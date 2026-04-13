const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const nodemailer = require("nodemailer");

exports.sendSupportNotification = onDocumentCreated({
  document: "support_requests/{docId}",
  // Update the secret name to match your Mailtrap secret
  secrets: ["MAILTRAP_PASSWORD"],
}, async (event) => {
  const snapshot = event.data;
  if (!snapshot) return null;

  const data = snapshot.data();

  // 1. Configure SMTP Transporter for Mailtrap Sandbox
  const transporter = nodemailer.createTransport({
    host: "sandbox.smtp.mailtrap.io",
    port: 2525,
    auth: {
      user: "ba074235d91cd3",
      pass: process.env.MAILTRAP_PASSWORD,
    },
  });

  // 2. Customise email content
  const mailOptions = {
    from: '"Ryder Cup Travel Services Support" <rcts@greenmail.net>',
    to: "rcts@greenmail.net",
    subject: `[SANDBOX] New Support Request from ${data.user_ref || "Guest"}`,
    html: `
      <h3>New Support Entry</h3>
      <p><strong>User Reference:</strong> ${data.user_ref}</p>
      <p><strong>Name:</strong> ${data.user_name || "N/A"}</p>
      <p><strong>Email:</strong> ${data.user_email || "N/A"}</p>
      <hr>
      <p><strong>Subject:</strong> ${data.subject}</p>
      <p><strong>Message:</strong></p>
      <p>${data.message}</p>
      <hr>
      <p><strong>Timestamp:</strong> ${new Date().toLocaleString("en-GB")}</p>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log("Support email sent to Mailtrap Sandbox successfully");
  } catch (error) {
    console.error("Error sending email:", error);
  }
});