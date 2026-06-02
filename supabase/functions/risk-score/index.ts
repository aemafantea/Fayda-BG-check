// Rule-based risk scoring for a background check
// Computes a 0-100 score (higher = riskier) and a risk_level enum.
import { handleCors, corsHeaders } from '../_shared/cors.ts';
import { getServiceClient, getUser } from '../_shared/supabase.ts';

type Factor = { code: string; weight: number; description: string };

Deno.serve(async (req) => {
  const cors = handleCors(req); if (cors) return cors;
  try {
    await getUser(req); // require auth
    const { background_check_id } = await req.json();
    if (!background_check_id) throw new Error('background_check_id required');

    const sb = getServiceClient();
    const { data: bg, error } = await sb
      .from('background_checks')
      .select('id, candidate_id, check_types')
      .eq('id', background_check_id).single();
    if (error || !bg) throw new Error('background_check not found');

    const { data: cand } = await sb
      .from('candidates')
      .select('id, profile_id, years_experience')
      .eq('id', bg.candidate_id).single();

    const { data: profile } = await sb
      .from('profiles').select('*').eq('id', cand!.profile_id).single();

    const [{ data: emp }, { data: refs }, { data: crims }, { data: docs }] = await Promise.all([
      sb.from('employment_history').select('*').eq('candidate_id', cand!.id),
      sb.from('references').select('*').eq('background_check_id', bg.id),
      sb.from('criminal_records').select('*').eq('background_check_id', bg.id),
      sb.from('documents').select('*').eq('owner_id', cand!.profile_id),
    ]);

    const factors: Factor[] = [];
    let score = 0;

    // 1. Identity verification
    if (profile?.fayda_verification_status !== 'verified') {
      score += 30;
      factors.push({ code: 'no_fayda', weight: 30, description: 'Fayda ID not verified' });
    }

    // 2. Employment gaps & verification rate
    if (emp && emp.length > 0) {
      const verifiedRate = emp.filter(e => e.verified).length / emp.length;
      if (verifiedRate < 0.5) {
        const w = Math.round(20 * (1 - verifiedRate));
        score += w;
        factors.push({ code: 'low_emp_verification', weight: w,
          description: `Only ${(verifiedRate*100).toFixed(0)}% of employment history verified` });
      }
      // Detect gaps > 6 months
      const sorted = [...emp].sort((a,b)=>a.start_date.localeCompare(b.start_date));
      for (let i=1; i<sorted.length; i++) {
        const prevEnd = sorted[i-1].end_date ? new Date(sorted[i-1].end_date) : new Date();
        const curStart = new Date(sorted[i].start_date);
        const months = (curStart.getTime() - prevEnd.getTime()) / (1000*60*60*24*30);
        if (months > 6) {
          score += 5;
          factors.push({ code: 'employment_gap', weight: 5,
            description: `Gap of ${Math.round(months)} months between ${sorted[i-1].employer_name} and ${sorted[i].employer_name}` });
        }
      }
    } else {
      score += 10;
      factors.push({ code: 'no_employment_history', weight: 10, description: 'No employment history provided' });
    }

    // 3. References
    if (!refs || refs.length === 0) {
      score += 10;
      factors.push({ code: 'no_references', weight: 10, description: 'No references on file' });
    } else {
      const responded = refs.filter(r => r.response_received);
      if (responded.length > 0) {
        const avgRating = responded.reduce((s,r)=>s+(r.rating??0),0) / responded.length;
        if (avgRating < 3) {
          const w = Math.round((3 - avgRating) * 10);
          score += w;
          factors.push({ code: 'low_reference_rating', weight: w,
            description: `Average reference rating ${avgRating.toFixed(1)}/5` });
        }
        const wouldNotRehire = responded.filter(r => r.would_rehire === false).length;
        if (wouldNotRehire > 0) {
          score += 15;
          factors.push({ code: 'no_rehire', weight: 15,
            description: `${wouldNotRehire} referee(s) would not rehire` });
        }
      }
    }

    // 4. Criminal records
    if (crims && crims.length > 0) {
      const positives = crims.filter(c => c.has_records);
      if (positives.length > 0) {
        score += 40;
        factors.push({ code: 'criminal_record_found', weight: 40,
          description: `${positives.length} jurisdiction(s) reported records` });
      }
    } else if (bg.check_types?.includes('criminal_record' as never)) {
      score += 5;
      factors.push({ code: 'criminal_check_pending', weight: 5, description: 'Criminal check pending' });
    }

    // 5. Document completeness
    if (!docs || docs.length < 2) {
      score += 5;
      factors.push({ code: 'few_documents', weight: 5, description: 'Few supporting documents uploaded' });
    }

    score = Math.min(100, Math.max(0, score));
    const risk_level =
      score >= 70 ? 'critical' :
      score >= 50 ? 'high' :
      score >= 25 ? 'medium' : 'low';

    const { error: uErr } = await sb.from('background_checks').update({
      risk_score: score, risk_level, risk_factors: factors,
    }).eq('id', bg.id);
    if (uErr) throw uErr;

    return new Response(JSON.stringify({ score, risk_level, factors }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
