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

app.post('/3d', (req, res) => {
    if (!req.files || Object.keys(req.files).length === 0) {
        return res.status(400).send('No files were uploaded.');
    }

    let uploadedFile = req.files.file; // 'file' should match the key used in the iOS Shortcut
    let ext = path.extname(uploadedFile.name);
    let fileName = 'file_' + new Date().toISOString().replace(/:/g, '-') + ext;

    uploadedFile.mv(fileName, function(err) {
        if (err) {
            console.log(err);
            return res.status(500).send(err);
        }

        console.log('The file was saved!');

        // Set executable permissions
        execSync('chmod +x ./prusaslicer/prusa-slicer');
        execSync('chmod +x ./prusaslicer/bin/bambu-studio');

        const outFile = 'out_' + new Date().toISOString().replace(/:/g, '-') + '.3mf';
        const machinePath = path.join(__dirname, 'profiles', 'machine.json');
        const processPath = path.join(__dirname, 'profiles', 'process.json');
        const filamentPath = path.join(__dirname, 'profiles', 'filament.json');

        exec(`./prusaslicer/bin/bambu-studio --load-settings "${machinePath};${processPath}" --load-filaments "${filamentPath}" --slice 0 --debug 2 --export-3mf ${outFile} ${fileName}`, (err, stdout, stderr) => {
            if (err) {
                console.log(err);
                return res.status(500).send('Error processing file');
            }

            console.log(`stdout: ${stdout}`);
            console.log(`stderr: ${stderr}`);

            const absoluteOutFilePath = path.resolve(__dirname, outFile);

            res.sendFile(absoluteOutFilePath, (err) => {
                if (err) {
                    console.log(err);
                    res.status(err.status).end();
                }
                // Clean up temporary files
                fs.unlinkSync(fileName);
                fs.unlinkSync(absoluteOutFilePath);
            });
        });
    });
});

app.listen(28508, () => {
    console.log('listening on 28508');
});
