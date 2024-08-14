const exec = require('child_process').exec;
const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path'); // Import path module
const cors = require('cors'); // Import the cors middleware
const app = express();

// Enable CORS for all routes
app.use(cors());

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
  const fileName = 'file_' + new Date().toISOString().replace(/:/g, '-') + '.' + ext;
  const jobId = new Date().toISOString(); // Unique job ID

  jobs[jobId] = { status: 'processing', fileName: fileName, resultFileName: null }; // Initialize job status

  fs.writeFile(fileName, b, 'binary', function (err) {
    if (err) {
      console.error('File write error:', err);
      jobs[jobId].status = 'failed';
      res.status(500).send('Error saving file');
      return;
    }

    console.log('The file was saved!');
    const outFile = 'out_' + new Date().toISOString().replace(/:/g, '-') + '.3mf';
    jobs[jobId].resultFileName = outFile;
    const { execSync } = require('child_process');

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
  res.json({ jobId: jobId, status: job.status });
});

// Result endpoint
app.get('/result', (req, res) => {
  const jobId = req.query.jobId;

  if (!jobId || !jobs[jobId]) {
    return res.status(404).send('Job not found');
  }

  const job = jobs[jobId];

  if (job.status === 'completed' && job.resultFileName) {
    const absoluteOutFilePath = path.resolve(__dirname, job.resultFileName);
    res.sendFile(absoluteOutFilePath, (err) => {
      if (err) {
        console.error('File send error:', err);
        res.status(err.status || 500).end();
      }
    });
  } else {
    res.status(404).send('Result not available yet');
  }
});

app.listen(28508, () => {
  console.log('listening on 28508');
});
