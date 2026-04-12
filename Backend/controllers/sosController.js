const nodemailer = require('nodemailer');
const Contact = require('../models/ContactModel');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

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

    await transporter.sendMail({
      from: `"StreeHelp SOS" <${process.env.EMAIL_USER}>`,
      to: emails.join(','),
      subject: '🚨 SOS ALERT - Immediate Help Needed!',
      html: `
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:24px;border:2px solid #E91E8C;border-radius:12px;">
          <h2 style="color:#E91E8C;">🚨 SOS Emergency Alert</h2>
          <p style="font-size:16px;">${message}</p>
          ${locationHtml}
          <p style="color:#888;font-size:13px;margin-top:16px;">This alert was triggered via StreeHelp safety app.</p>
        </div>
      `,
    });

    res.json({ success: true, message: 'SOS alert sent' });
  } catch (error) {
    console.error('SOS Email Error:', error.message);
    res.status(500).json({ success: false, message: 'Failed to send SOS alert' });
  }
};
