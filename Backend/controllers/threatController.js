const nodemailer = require('nodemailer');
const Contact = require('../models/ContactModel');
const User = require('../models/UserModel');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

/// Sends SOS alert when distress keyword is detected
exports.sendSosAlert = async (req, res) => {
  try {
    const contacts = await Contact.find({ userId: req.user.userId });

    if (!contacts.length) {
      return res.status(400).json({ success: false, message: 'No contacts found' });
    }

    const emails = contacts
      .map(c => c.email)
      .filter(e => e && e.includes('@'));

    if (!emails.length) {
      return res.status(400).json({ success: false, message: 'No valid email addresses found' });
    }

    const message = req.body.message || '🚨 SOS ALERT! I am in danger and need immediate help. Please contact me right away!';
    const lat = req.body.lat;
    const lng = req.body.lng;
    const alertType = req.body.alertType || 'MANUAL';

    const locationHtml = (lat && lng)
      ? `
        <div style="margin-top:16px;padding:14px;background:#fff3f8;border-radius:10px;border:1px solid #E91E8C;">
          <p style="margin:0 0 8px;font-weight:bold;color:#E91E8C;">📍 Live Location</p>
          <p style="margin:0 0 6px;font-size:13px;color:#555;">Latitude: ${lat} &nbsp;|&nbsp; Longitude: ${lng}</p>
          <a href="https://www.google.com/maps?q=${lat},${lng}" 
             style="display:inline-block;margin-top:6px;padding:10px 20px;background:#E91E8C;color:#fff;text-decoration:none;border-radius:8px;font-weight:bold;font-size:14px;">
            📍 Open in Google Maps
          </a>
        </div>`
      : `<p style="color:#888;font-size:13px;margin-top:12px;">⚠️ Location could not be determined.</p>`;

    const alertBadge = alertType === 'VOICE_DETECTED' 
      ? '<span style="background:#FF6B35;color:white;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:bold;">🎤 VOICE DETECTED</span>'
      : '<span style="background:#E91E8C;color:white;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:bold;">🚨 MANUAL ALERT</span>';

    await transporter.sendMail({
      from: `"StreeHelp SOS" <${process.env.EMAIL_USER}>`,
      to: emails.join(','),
      subject: `🚨 SOS ALERT - Immediate Help Needed! [${alertType}]`,
      html: `
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:24px;border:2px solid #E91E8C;border-radius:12px;background:#fafafa;">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
            <h2 style="color:#E91E8C;margin:0;">🚨 SOS Emergency Alert</h2>
            ${alertBadge}
          </div>
          <p style="font-size:16px;line-height:1.6;color:#333;">${message}</p>
          ${locationHtml}
          <div style="margin-top:20px;padding:12px;background:#fff9e6;border-left:4px solid #FFC107;border-radius:4px;">
            <p style="margin:0;font-size:13px;color:#666;">⏰ <strong>Time:</strong> ${new Date().toLocaleString()}</p>
          </div>
          <p style="color:#888;font-size:12px;margin-top:16px;text-align:center;">This alert was triggered via StreeHelp safety app. Please verify the person's safety immediately.</p>
        </div>
      `,
    });

    res.json({ success: true, message: 'SOS alert sent' });
  } catch (error) {
    console.error('SOS Email Error:', error.message);
    res.status(500).json({ success: false, message: 'Failed to send SOS alert' });
  }
};

/// Sends alert when voice threat is detected
exports.sendThreatAlert = async (req, res) => {
  try {
    const { detectedText, threatScore, threatLevel, lat, lng } = req.body;
    
    if (!threatLevel) {
      return res.status(400).json({ success: false, message: 'Threat level required' });
    }

    // Get user for notification
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Get emergency contacts
    const contacts = await Contact.find({ userId: req.user.userId });
    if (!contacts.length) {
      return res.status(400).json({ success: false, message: 'No emergency contacts found' });
    }

    const emails = contacts
      .map(c => c.email)
      .filter(e => e && e.includes('@'));

    if (!emails.length) {
      return res.status(400).json({ success: false, message: 'No valid email addresses found' });
    }

    // Threat level colors and icons
    const threatConfig = {
      'CRITICAL': { color: '#FF0000', icon: '🔴', urgency: 'CRITICAL - IMMEDIATE ACTION REQUIRED' },
      'HIGH': { color: '#FF6B35', icon: '🟠', urgency: 'HIGH - URGENT RESPONSE NEEDED' },
      'MEDIUM': { color: '#FFC107', icon: '🟡', urgency: 'MEDIUM - RESPONSE NEEDED' },
      'LOW': { color: '#4CAF50', icon: '🟢', urgency: 'LOW - MONITORING' },
    };

    const config = threatConfig[threatLevel] || threatConfig['MEDIUM'];

    const locationHtml = (lat && lng)
      ? `
        <div style="margin-top:16px;padding:14px;background:#f0f0f0;border-radius:10px;border-left:4px solid ${config.color};">
          <p style="margin:0 0 8px;font-weight:bold;color:${config.color};">📍 Location</p>
          <p style="margin:0 0 6px;font-size:13px;color:#555;">Lat: ${lat.toFixed(6)} | Lng: ${lng.toFixed(6)}</p>
          <a href="https://www.google.com/maps?q=${lat},${lng}" 
             style="display:inline-block;margin-top:6px;padding:10px 16px;background:${config.color};color:#fff;text-decoration:none;border-radius:6px;font-weight:bold;font-size:13px;">
            📍 View on Maps
          </a>
        </div>`
      : '';

    await transporter.sendMail({
      from: `"StreeHelp Threat Alert" <${process.env.EMAIL_USER}>`,
      to: emails.join(','),
      subject: `${config.icon} ${config.urgency} - Voice Threat Detected`,
      html: `
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:24px;border:2px solid ${config.color};border-radius:12px;background:#fafafa;">
          <div style="text-align:center;margin-bottom:20px;">
            <h1 style="margin:0;font-size:32px;">${config.icon}</h1>
            <h2 style="color:${config.color};margin:8px 0 0 0;">Threat Detected - ${threatLevel}</h2>
            <p style="color:#666;margin:4px 0 0 0;font-size:13px;">${config.urgency}</p>
          </div>

          <div style="background:${config.color}20;padding:16px;border-radius:8px;margin-bottom:16px;border-left:4px solid ${config.color};">
            <p style="margin:0 0 8px 0;font-weight:bold;color:#333;">🎤 Detected Voice Activity:</p>
            <p style="margin:0;font-style:italic;color:#555;font-size:14px;">"${detectedText}"</p>
          </div>

          <div style="background:#f5f5f5;padding:12px;border-radius:8px;margin-bottom:16px;">
            <p style="margin:0 0 8px 0;font-weight:bold;color:#333;">Analysis Results:</p>
            <table style="width:100%;font-size:13px;line-height:1.8;">
              <tr>
                <td style="color:#666;"><strong>Threat Score:</strong></td>
                <td style="color:${config.color};font-weight:bold;">${(threatScore * 100).toFixed(1)}%</td>
              </tr>
              <tr style="background:#fff;">
                <td style="color:#666;"><strong>Threat Level:</strong></td>
                <td style="color:${config.color};font-weight:bold;">${threatLevel}</td>
              </tr>
              <tr>
                <td style="color:#666;"><strong>Detection Time:</strong></td>
                <td>${new Date().toLocaleString()}</td>
              </tr>
            </table>
          </div>

          ${locationHtml}

          <div style="background:#FFF3CD;padding:12px;border-radius:8px;margin-top:16px;border-left:4px solid #FFC107;">
            <p style="margin:0;font-size:12px;color:#856404;"><strong>⚠️ Action Required:</strong></p>
            <p style="margin:4px 0 0 0;font-size:12px;color:#856404;">
              A potential threat has been detected. Please contact ${user.name} immediately to ensure their safety.
            </p>
          </div>

          <p style="color:#888;font-size:11px;margin-top:16px;text-align:center;border-top:1px solid #ddd;padding-top:12px;">
            This is an automated alert from StreeHelp Safety App. The system detected concerning voice patterns during active monitoring.
          </p>
        </div>
      `,
    });

    res.json({ 
      success: true, 
      message: 'Threat alert sent to emergency contacts',
      threatData: {
        threatLevel,
        threatScore,
        contactsNotified: emails.length,
      }
    });
  } catch (error) {
    console.error('Threat Alert Error:', error.message);
    res.status(500).json({ success: false, message: 'Failed to send threat alert' });
  }
};

/// Logs threat incidents for analytics
exports.reportThreat = async (req, res) => {
  try {
    const { detectedText, threatScore, threatLevel, lat, lng } = req.body;

    // In a production system, you'd save this to a database
    console.log('Threat Reported:', {
      userId: req.user.userId,
      detectedText,
      threatScore,
      threatLevel,
      location: { lat, lng },
      timestamp: new Date(),
    });

    res.json({ 
      success: true, 
      message: 'Threat report logged',
      threatId: `THREAT_${Date.now()}`,
    });
  } catch (error) {
    console.error('Threat Report Error:', error.message);
    res.status(500).json({ success: false, message: 'Failed to log threat report' });
  }
};
