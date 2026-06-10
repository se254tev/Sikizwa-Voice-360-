const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const xss = require('xss-clean');
const csurf = require('csurf');
const session = require('express-session');
const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');

const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const reportsRoutes = require('./routes/reports');
const emergenciesRoutes = require('./routes/emergencies');
const counsellorsRoutes = require('./routes/counsellors');
const aiRoutes = require('./routes/ai');
const uploadsRoutes = require('./routes/uploads');
const analyticsRoutes = require('./routes/analytics');
const notificationsRoutes = require('./routes/notifications');
const supportChatsRoutes = require('./routes/supportChats');
const learningResourcesRoutes = require('./routes/learningResources');
const safeSpacesRoutes = require('./routes/safeSpaces');
const distressSignalsRoutes = require('./routes/distressSignals');
const distressSignalsAdminRoutes = require('./routes/distressSignalsAdmin');
const pendantEmergencyRoutes = require('./routes/pendantEmergency');
const deviceRoutes = require('./routes/device');
const userRoutes = require('./routes/user');
const logger = require('./config/logger');
const { ApiError } = require('./utils/apiError');
const { NOT_FOUND_ERRORS } = require('./utils/errorMessages');
const errorHandler = require('./middleware/errorHandler');

const swaggerDoc = YAML.load('./docs/swagger.yaml');
const isProduction = process.env.NODE_ENV === 'production';

const app = express();

// Trust the ingress proxy so req.ip reflects the real client address.
app.set('trust proxy', 1);

const defaultCorsOrigins = [
  'https://sikizwa.com',
  'https://app.sikizwa.com',
  'http://localhost:3000',
];

const extraOrigins = typeof process.env.CORS_ORIGINS === 'string'
  ? process.env.CORS_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean)
  : [];

const corsOrigins = Array.from(new Set([...defaultCorsOrigins, ...extraOrigins]));

const corsOptions = {
  origin(origin, callback) {
    if (!origin || corsOrigins.includes(origin)) {
      callback(null, true);
      return;
    }

    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  optionsSuccessStatus: 200,
};

app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'", 'https:'],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:'],
        connectSrc: ["'self'", 'https:'],
        objectSrc: ["'none'"],
        baseUri: ["'self'"],
        formAction: ["'self'"],
      },
    },
    referrerPolicy: { policy: 'same-origin' },
  })
);
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));
// Parse JSON first, then URL-encoded bodies, then cookies
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cookieParser());
app.use(xss());
app.use(morgan('combined'));

app.use((req, res, next) => {
  logger.info('Incoming request', {
    method: req.method,
    path: req.originalUrl,
    ip: getClientIp(req),
  });
  next();
});

const getClientIp = (req) =>
  req.ip || req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket.remoteAddress || 'unknown';

app.use((req, res, next) => {
  const isAuthRelated =
    req.path === '/web/csrf-token' ||
    req.path === '/health' ||
    req.path.startsWith('/api/auth');

  if (isAuthRelated) {
    logger.info('Request received', {
      method: req.method,
      path: req.originalUrl,
      ip: getClientIp(req),
      forwardedFor: req.headers['x-forwarded-for'] || null,
      realIp: req.headers['x-real-ip'] || null,
      userAgent: req.headers['user-agent'] || null,
    });
  }

  next();
});

const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 500,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => getClientIp(req),
  skip: (req) => !isProduction || req.path === '/health',
  handler: (req, res) => {
    logger.warn('Rate limit exceeded', {
      path: req.originalUrl,
      ip: getClientIp(req),
      forwardedFor: req.headers['x-forwarded-for'] || null,
    });

    res.status(429).json({
      success: false,
      errorCode: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many requests. Please try again later.',
    });
  },
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => getClientIp(req),
  skip: (req) => !isProduction || req.path === '/health',
  handler: (req, res) => {
    logger.warn('Auth rate limit exceeded', {
      path: req.originalUrl,
      ip: getClientIp(req),
      forwardedFor: req.headers['x-forwarded-for'] || null,
    });

    res.status(429).json({
      success: false,
      errorCode: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many requests. Please try again later.',
    });
  },
});

// --- Dual architecture: /web (stateful) vs /api (stateless) ---
// Web router (stateful): session + csurf for browser-based UI
const webRouter = express.Router();

const sessionCookieSecure = typeof process.env.SESSION_COOKIE_SECURE === 'string'
  ? process.env.SESSION_COOKIE_SECURE === 'true'
  : isProduction;
const sessionCookieMaxAge = Number(process.env.SESSION_COOKIE_MAX_AGE) || 24 * 60 * 60 * 1000;

const sessionConfig = {
  name: process.env.SESSION_NAME || 'sikizwa_session',
  secret: process.env.SESSION_SECRET || 'dev-secret-change-me',
  resave: false,
  saveUninitialized: false,
  proxy: true,
  cookie: {
    httpOnly: true,
    secure: sessionCookieSecure,
    sameSite: 'strict',
    maxAge: sessionCookieMaxAge,
    path: '/',
  },
};

webRouter.use(session(sessionConfig));
webRouter.use(csurf());

// CSRF token endpoint for browser UI under /web
webRouter.get('/csrf-token', (req, res) => {
  logger.info('Web CSRF token generated', { ip: getClientIp(req) });
  res.json({ success: true, csrfToken: req.csrfToken() });
});

// Mount browser-only routes under /web
webRouter.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerDoc));
webRouter.use('/admin', adminRoutes);

app.use('/web', webRouter);

// Note: API routes mounted below are stateless and MUST NOT use session/csurf.

if (isProduction) {
  app.use(generalLimiter);
  app.use('/api/auth', authLimiter);
  app.use('/web/csrf-token', authLimiter);
}

app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerDoc));
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/admin', adminRoutes);
logger.info('Admin router mounted', {
  paths: ['/api/admin', '/admin'],
});
app.use('/api/reports', reportsRoutes);
app.use('/api/emergencies', emergenciesRoutes);
app.use('/api/counsellors', counsellorsRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/uploads', uploadsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/support-chats', supportChatsRoutes);
app.use('/api/learning-resources', learningResourcesRoutes);
app.use('/api/safe-spaces', safeSpacesRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/distress-signal', distressSignalsRoutes);
app.use('/api/distress-signals', distressSignalsAdminRoutes);
app.use('/api/emergency', pendantEmergencyRoutes);
app.use('/api/device', deviceRoutes);
app.use('/api/user', userRoutes);

app.get('/health', (req, res) => {
  logger.info('Health check satisfied', {
    ip: getClientIp(req),
    forwardedFor: req.headers['x-forwarded-for'] || null,
  });

  res.json({
    success: true,
    status: 'OK',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

app.use((req, res, next) => {
  next(
    new ApiError({
      statusCode: 404,
      message: NOT_FOUND_ERRORS.routeNotFound.message,
      errorCode: NOT_FOUND_ERRORS.routeNotFound.errorCode,
    })
  );
});

app.use(errorHandler);

module.exports = app;
