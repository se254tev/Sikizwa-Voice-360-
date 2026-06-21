function scoreEmergency(payload) {
  const { panic, location, notes } = payload;
  let score = 0;
  if (panic) score += 0.35;
  if (notes && /help|kill|die|danger|ambulance/i.test(notes)) score += 0.35;
  if (location && location.coordinates?.length === 2) score += 0.15;
  return score >= 0.8 ? 'emergency' : score >= 0.5 ? 'high' : score >= 0.25 ? 'medium' : 'low';
}

module.exports = { scoreEmergency };
