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

function formatReportLocation(report) {
  const text = typeof report?.locationText === 'string' && report.locationText.trim().length > 0
    ? report.locationText.trim()
    : null;

  if (text) {
    return text;
  }

  if (report?.location && typeof report.location === 'object' && Array.isArray(report.location.coordinates) && report.location.coordinates.length === 2) {
    const [lng, lat] = report.location.coordinates;
    return `Lat ${lat}, Lng ${lng}`;
  }

  if (typeof report?.location === 'string' && report.location.trim().length > 0) {
    return report.location.trim();
  }

  return null;
}

function serializeReport(report) {
  const createdAt = report?.createdAt instanceof Date ? report.createdAt : report?.createdAt ? new Date(report.createdAt) : null;
  const timestamp = report?.timestamp instanceof Date ? report.timestamp : report?.timestamp ? new Date(report.timestamp) : null;
  const riskLevel = normalizeRisk(report?.riskLevel);
  const description = typeof report?.description === 'string' && report.description.trim().length > 0
    ? report.description
    : '';
  const incidentType = typeof report?.incidentType === 'string' && report.incidentType.trim().length > 0
    ? report.incidentType.trim()
    : typeof report?.title === 'string' && report.title.trim().length > 0
      ? report.title.trim()
      : formatTitle(report?.type);
  const title = typeof report?.title === 'string' && report.title.trim().length > 0
    ? report.title.trim()
    : incidentType;

  return {
    id: report?._id ? String(report._id) : report?.id ? String(report.id) : '',
    type: report?.type || 'support',
    reportType: report?.reportType || 'problem',
    incidentType,
    anonymousSubmission: Boolean(report?.anonymousSubmission),
    priority: typeof report?.priority === 'string' && report.priority.trim().length > 0 ? report.priority : 'medium',
    title,
    description,
    emotional_summary: report?.emotional_summary || description,
    mood_status: report?.mood_status || inferMoodStatus(riskLevel),
    risk_level: riskLevel,
    riskLevel: riskLevel,
    status: report?.status || 'pending',
    created_at: createdAt ? createdAt.toISOString() : null,
    createdAt: createdAt ? createdAt.toISOString() : null,
    timestamp: timestamp ? timestamp.toISOString() : null,
    media: Array.isArray(report?.media) ? report.media : [],
    location: formatReportLocation(report),
  };
}

module.exports = {
  formatTitle,
  normalizeRisk,
  inferMoodStatus,
  serializeReport,
};
