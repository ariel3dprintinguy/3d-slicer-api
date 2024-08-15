const express = require('express');
const bodyParser = require('body-parser');
const fileUpload = require('express-fileupload');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const { exec, execSync } = require('child_process');
const app = express();

// Enable CORS for all routes
app.use(cors());

// Use express-fileupload middleware
app.use(fileUpload({
    createParentPath: true,
    limits: { fileSize: 50 * 1024 * 1024 }, // 50MB limit
}));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

app.get('/', (req, res) => {
    res.send('hello world');
});

app.get('/diagnose', (req, res) => {
    console.log('Running diagnostics');
    let diagnosticResults = {};

    // Function to run a command and capture its output
    const runCommand = (command) => {
        return new Promise((resolve, reject) => {
            exec(command, (error, stdout, stderr) => {
                resolve({ error, stdout, stderr });
            });
        });
    };

    // Run a series of diagnostic commands
    Promise.all([
        runCommand('whoami'),
        runCommand('pwd'),
        runCommand('ls -la ./prusaslicer/bin'),
        runCommand('file ./prusaslicer/bin/bambu-studio'),
        runCommand('ldd ./prusaslicer/bin/bambu-studio'),
        runCommand('./prusaslicer/bin/bambu-studio --version'),
        runCommand('env'),
    ]).then(results => {
        diagnosticResults = {
            user: results[0],
            currentDirectory: results[1],
            binContents: results[2],
            fileInfo: results[3],
            libraries: results[4],
            version: results[5],
            environment: results[6]
        };
        res.json(diagnosticResults);
    }).catch(error => {
        console.error('Error running diagnostics:', error);
        res.status(500).json({ error: 'Error running diagnostics' });
    });
});
app.post('/3d', (req, res) => {
    console.log('Received 3D print request');
    if (!req.files || Object.keys(req.files).length === 0) {
        return res.status(400).send('No files were uploaded.');
    }

    let uploadedFile = req.files.file;
    let ext = path.extname(uploadedFile.name);
    let fileName = 'file_' + new Date().toISOString().replace(/:/g, '-') + ext;

    console.log('Saving file:', fileName);
    uploadedFile.mv(fileName, function(err) {
        if (err) {
            console.error('Error saving file:', err);
            return res.status(500).send(err);
        }

        console.log('File saved successfully');

        // Log current working directory and file permissions
        console.log('Current working directory:', process.cwd());
        try {
            const fileStats = fs.statSync('./prusaslicer/bin/bambu-studio');
            console.log('Bambu Studio file permissions:', fileStats.mode.toString(8));
        } catch (error) {
            console.error('Error checking Bambu Studio file:', error);
        }

        // Set executable permissions
        try {
            execSync('chmod +x ./prusaslicer/prusa-slicer');
            execSync('chmod +x ./prusaslicer/bin/bambu-studio');
            console.log('Executable permissions set');
        } catch (error) {
            console.error('Error setting executable permissions:', error);
        }

        const outFile = 'out_' + new Date().toISOString().replace(/:/g, '-') + '.3mf';
        const machinePath = path.join(__dirname, 'profiles', 'machine.json');
        const processPath = path.join(__dirname, 'profiles', 'process.json');
        const filamentPath = path.join(__dirname, 'profiles', 'filament.json');

        // Log the full command
        const fullCommand = `./prusaslicer/bin/bambu-studio --load-settings "${machinePath};${processPath}" --load-filaments "${filamentPath}" --slice 0 --debug 2 --export-3mf ${outFile} ${fileName}`;
        console.log('Executing command:', fullCommand);

    exec(fullCommand, { maxBuffer: 1024 * 1024 * 10 }, (err, stdout, stderr) => {
        console.log('Bambu Studio execution completed');
        if (err) {
            console.error('Error processing file:', err);
            console.log('Exit code:', err.code);
            console.log('Signal received:', err.signal);
            return res.status(500).json({
                error: 'Error processing file',
                details: {
                    message: err.message,
                    code: err.code,
                    signal: err.signal,
                    stdout: stdout,
                    stderr: stderr
                }
            });
        }
    });
});

// Add a test route for Bambu Studio
app.get('/test-bambu', (req, res) => {
    exec('./prusaslicer/bin/bambu-studio --version', (err, stdout, stderr) => {
        if (err) {
            console.error('Error running Bambu Studio:', err);
            return res.status(500).send('Error running Bambu Studio');
        }
        res.send(`Bambu Studio version: ${stdout}\nErrors: ${stderr}`);
    });
});

app.listen(28508, () => {
    console.log('Server listening on port 28508');
});
