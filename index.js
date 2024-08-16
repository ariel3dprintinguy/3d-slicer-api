const express = require('express');
const fileUpload = require('express-fileupload');
const fs = require('fs').promises;
const path = require('path');
const cors = require('cors');
const { exec } = require('child_process');
const { promisify } = require('util');

const app = express();
const execPromise = promisify(exec);

// Enable CORS for all routes
app.use(cors());

// Use express-fileupload middleware with optimized settings
app.use(fileUpload({
    createParentPath: true,
    limits: { 
        fileSize: 50 * 1024 * 1024, // 50MB limit
        files: 1 // Limit to 1 file per request
    },
    abortOnLimit: true, // Automatically abort the request if file size limit is exceeded
    useTempFiles: true, // Use temp files instead of memory for file uploads
    tempFileDir: '/tmp/' // Specify temp file directory
}));

app.get('/', (req, res) => {
    res.send('hello world');
});

app.post('/3d', async (req, res) => {
    try {
        if (!req.files || Object.keys(req.files).length === 0) {
            return res.status(400).send('No files were uploaded.');
        }

        const uploadedFile = req.files.file;
        const ext = path.extname(uploadedFile.name);
        const fileName = `file_${Date.now()}${ext}`;
        const filePath = path.join('/tmp', fileName);

        await uploadedFile.mv(filePath);
        console.log('The file was saved!');

        // Set executable permissions
        await execPromise('chmod +x ./prusaslicer/prusa-slicer');
        await execPromise('chmod +x ./prusaslicer/bin/bambu-studio');

        const outFile = `out_${Date.now()}.3mf`;
        const outFilePath = path.join('/tmp', outFile);

        const machinePath = path.join(__dirname, 'profiles', 'machine.json');
        const processPath = path.join(__dirname, 'profiles', 'process.json');
        const filamentPath = path.join(__dirname, 'profiles', 'filament.json');

        const command = `./prusaslicer/prusa-slicer --load-settings "${machinePath};${processPath}" --load-filaments "${filamentPath}" --slice 0 --export-3mf ${outFilePath} ${filePath}`;

        await execPromise(command);

        res.sendFile(outFilePath, async (err) => {
            if (err) {
                console.error(err);
                res.status(500).end();
            }
            // Clean up temporary files
            await Promise.all([
                fs.unlink(filePath),
                fs.unlink(outFilePath)
            ]);
        });
    } catch (error) {
        console.error(error);
        res.status(500).send('Error processing file');
    }
});

const PORT = process.env.PORT || 28508;
app.listen(PORT, () => {
    console.log(`Listening on port ${PORT}`);
});
