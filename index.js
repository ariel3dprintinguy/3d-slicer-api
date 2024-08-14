const exec = require('child_process').exec;
const express = require('express');
const multer = require('multer');
const fileUpload = require('express-fileupload');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path'); // Import path module
const app = express();

// In-memory job storage
const jobs = {}; 

app.use(
  bodyParser.raw({ limit: '50mb', type: ['model/*'] })
);

app.get('/', (req, res) => {
  res.send('hello world');
});

app.post('/3d', (req, res) => {
  const type = req.get('Content-Type');
  const ext = type.split('/')[1];
  console.log('Content-Type:', type);
  console.log('File extension:', ext);

  const b = req.body;
  const fileName = 'file_' + new Date().toISOString() + '.' + ext;
  const jobId = new Date().toISOString(); // Unique job ID

  jobs[jobId] = { status: 'processing', fileName: fileName }; // Initialize job status

  fs.writeFile(fileName, b, 'binary', function (err) {
    if (err) {
      console.error('File write error:', err);
      jobs[jobId].status = 'failed';
      res.status(500).send('Error saving file');
      return;
    }

    console.log('The file was saved!');
    const outFile = 'out_' + new Date().toISOString() + '.3mf';

    // Set executable permissions
    execSync('chmod +x ./prusaslicer/prusa-slicer');
    execSync('chmod +x ./prusaslicer/bin/bambu-studio');

    exec(`./prusaslicer/prusa-slicer --slice 0 --debug 2 --export-3mf ${outFile} ${fileName}`, (err, stdout, stderr) => {
      if (err) {
        console.error('Slicing error:', err);
        console.error('stderr:', stderr);
        jobs[jobId].status = 'failed';
        res.status(500).send('Error slicing file');
        return;
      }

      console.log(`stdout: ${stdout}`);
      console.error(`stderr: ${stderr}`);

      // Use path.resolve to create an absolute path
      const absoluteOutFilePath = path.resolve(__dirname, outFile);

      jobs[jobId].status = 'completed';

      res.json({ jobId: jobId, message: 'Processing started', status: jobs[jobId].status });
    });
  });
});

// Status endpoint
app.get('/status', (req, res) => {
  const jobId = req.query.jobId;

  if (!jobId || !jobs[jobId]) {
    return res.status(404).send('Job not found');
  }

  const job = jobs[jobId];

  if (job.status === 'completed') {
    const absoluteOutFilePath = path.resolve(__dirname, job.fileName);
    res.sendFile(absoluteOutFilePath, (err) => {
      if (err) {
        console.error('File send error:', err);
        res.status(err.status || 500).end();
      }
    });
  } else {
    res.json({ jobId: jobId, status: job.status });
  }
});

app.listen(28508, () => {
  console.log('listening on 28508');
});
