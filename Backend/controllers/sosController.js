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

    await transporter.sendMail({
      from: `"StreeHelp SOS" <${process.env.EMAIL_USER}>`,
      to: emails.join(','),
      subject: '🚨 SOS ALERT - Immediate Help Needed!',
      html: `
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:24px;border:2px solid #E91E8C;border-radius:12px;">
          <h2 style="color:#E91E8C;">🚨 SOS Emergency Alert</h2>
          <p style="font-size:16px;">${message}</p>
          <p style="color:#888;font-size:13px;">This alert was triggered via StreeHelp safety app.</p>
        </div>
      `,
    });

    res.json({ success: true, message: 'SOS alert sent' });
  } catch (error) {
    console.error('SOS Email Error:', error.message);
    res.status(500).json({ success: false, message: 'Failed to send SOS alert' });
  }
};
