const functions = require('firebase-functions');
const admin = require('firebase-admin');
const Excel = require('exceljs');

admin.initializeApp();
const db = admin.firestore();
const bucket = admin.storage().bucket();

// HTTP function to generate an Excel report from Firestore data and upload to Storage
exports.generateReport = functions.https.onRequest(async (req, res) => {
  try {
    // simple auth: expect Firebase ID token in Authorization: Bearer <token>
    const authHeader = req.get('Authorization') || req.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    const idToken = authHeader.split('Bearer ')[1];
    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (err) {
      return res.status(401).json({ error: 'Invalid ID token' });
    }

    // Collections to export - adjust names to your schema
    const collections = ['actividades', 'productores', 'riegos', 'fertilizaciones', 'cosechas'];

    const workbook = new Excel.Workbook();

    for (const col of collections) {
      const snap = await db.collection(col).get();
      const rows = [];
      snap.forEach(doc => {
        rows.push({ id: doc.id, ...doc.data() });
      });

      const sheet = workbook.addWorksheet(col);
      if (rows.length === 0) {
        sheet.addRow(['(sin datos)']);
        continue;
      }

      // determine columns from union of keys of first row (simple heuristic)
      const keys = Object.keys(rows[0]);
      sheet.columns = keys.map(k => ({ header: k, key: k }));
      for (const r of rows) {
        // convert nested objects to JSON strings to avoid complex types
        const flat = {};
        for (const k of keys) {
          const v = r[k];
          flat[k] = (v && typeof v === 'object') ? JSON.stringify(v) : v;
        }
        sheet.addRow(flat);
      }
    }

    const buffer = await workbook.xlsx.writeBuffer();
    const fileName = `reports/report-${Date.now()}.xlsx`;
    const file = bucket.file(fileName);

    await file.save(Buffer.from(buffer), {
      metadata: {
        contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      }
    });

    // signed URL (1 hour)
    const [url] = await file.getSignedUrl({
      action: 'read',
      expires: Date.now() + 60 * 60 * 1000
    });

    return res.json({ url, path: fileName });
  } catch (err) {
    console.error('generateReport error', err);
    return res.status(500).json({ error: err.message || String(err) });
  }
});
