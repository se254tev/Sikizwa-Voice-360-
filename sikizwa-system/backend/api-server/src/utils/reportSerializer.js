function formatTitle(type) {
  const normalized = typeof type === 'string' && type.trim().length > 0 ? type.replace(/_/g, ' ').trim() : 'support';
  if (!normalized) {
    return 'Support update';
  }

  return normalized.charAt(0).toUpperCase() + normalized.slice(1);
}

function normalizeRisk(riskLevel) {
  const value = typeof riskLevel === 'string' ? riskLevel.toLowerCase() : 'low';

  if (value === 'medium' || value === 'moderate') {
    return 'medium';
  }

  if (value === 'high' || value === 'critical') {
    return 'high';
  }

  if (value === 'emergency') {
    return 'emergency';
  }

  return 'low';
}

function inferMoodStatus(riskLevel) {
  const normalized = normalizeRisk(riskLevel);

  if (normalized === 'emergency') {
    return 'Urgent';
  }

  if (normalized === 'high') {
    return 'Elevated';
  }

  if (normalized === 'medium') {
    return 'Steady';
  }

  return 'Calm';
}

function serializeReport(report) {
  const createdAt = report?.createdAt instanceof Date ? report.createdAt : report?.createdAt ? new Date(report.createdAt) : null;
  const riskLevel = normalizeRisk(report?.riskLevel);
  const description = typeof report?.description === 'string' && report.description.trim().length > 0
    ? report.description
    : '';

  return {
    id: report?._id ? String(report._id) : report?.id ? String(report.id) : '',
    type: report?.type || 'support',
    title: report?.title || formatTitle(report?.type),
    description,
    emotional_summary: report?.emotional_summary || description,
    mood_status: report?.mood_status || inferMoodStatus(riskLevel),
    risk_level: riskLevel,
    riskLevel: riskLevel,
    status: report?.status || 'open',
    created_at: createdAt ? createdAt.toISOString() : null,
    createdAt: createdAt ? createdAt.toISOString() : null,
    media: Array.isArray(report?.media) ? report.media : [],
    location: report?.location || null,
  };
}

module.exports = {
  formatTitle,
  normalizeRisk,
  inferMoodStatus,
  serializeReport,
};
