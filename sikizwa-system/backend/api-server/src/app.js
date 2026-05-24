const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const xss = require('xss-clean');
const csurf = require('csurf');
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
const deviceRoutes = require('./routes/device');
const logger = require('./config/logger');
const { ApiError } = require('./utils/apiError');
const { NOT_FOUND_ERRORS } = require('./utils/errorMessages');
const errorHandler = require('./middleware/errorHandler');

const swaggerDoc = YAML.load('./docs/swagger.yaml');

const app = express();

app.set('trust proxy', 1);

const allowedOrigins = ['https://sikizwa-voice-360.vercel.app'];

const corsOptions = {
  origin: function (origin, callback) {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
      return;
    }

    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  optionsSuccessStatus: 200,
};

app.use(helmet());
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));
app.use(cookieParser());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('combined'));
app.use(xss());

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.ip,
  skip: (req) => process.env.NODE_ENV !== 'production' && req.ip === undefined,
});
app.use(limiter);

const csrfProtection = csurf({
  cookie: {
    httpOnly: true,
    sameSite: 'strict',
    secure: process.env.NODE_ENV === 'production',
  },
});

const csrfExemptRoutes = new Set(['/api/admin/signup', '/api/admin/login']);

app.use((req, res, next) => {
  if (csrfExemptRoutes.has(req.path)) {
    logger.debug('CSRF protection skipped for route', {
      path: req.path,
      origin: req.get('origin') || req.get('referer') || null,
      hasAuthorization: Boolean(req.headers.authorization),
    });
    return next();
  }

  return csrfProtection(req, res, next);
});

app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerDoc));
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
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
app.use('/api/device', deviceRoutes);

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.get('/api/csrf-token', (req, res) => res.json({ csrfToken: req.csrfToken() }));

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
