const express = require('express');
const fileUpload = require('express-fileupload');
const fs = require('fs').promises;
const path = require('path');
const cors = require('cors');
const { exec } = require('child_process');
const { promisify } = require('util');
const axios = require('axios');
const FormData = require('form-data');

const app = express();
const execPromise = promisify(exec);

app.use(cors());
app.use(fileUpload({
    createParentPath: true,
    limits: { 
        fileSize: 50 * 1024 * 1024,
        files: 1
    },
    abortOnLimit: true,
    useTempFiles: true,
    tempFileDir: '/tmp/'
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

        await execPromise('chmod +x ./prusaslicer/prusa-slicer');
        await execPromise('chmod +x ./prusaslicer/bin/bambu-studio');

        const outFile = `out_${Date.now()}.3mf`;
        const outFilePath = path.join('/tmp', outFile);
        const machinePath = path.join(__dirname, 'profiles', 'machine.json');
        const processPath = path.join(__dirname, 'profiles', 'process.json');
        const filamentPath = path.join(__dirname, 'profiles', 'filament.json');

        const command = `./prusaslicer/prusa-slicer --load-settings "${machinePath};${processPath}" --load-filaments "${filamentPath}" --slice 0 --export-3mf ${outFilePath} ${filePath}`;
        await execPromise(command);

        // Upload to bashupload.com
        const form = new FormData();
        form.append('file', fs.createReadStream(outFilePath));

        const uploadResponse = await axios.post('https://bashupload.com', form, {
            headers: form.getHeaders(),
            maxBodyLength: Infinity,
        });

        const uploadedUrl = uploadResponse.data.match(/wget (.*)/)[1];

        res.json({ url: uploadedUrl });

        // Clean up temporary files
        await Promise.all([
            fs.unlink(filePath),
            fs.unlink(outFilePath)
        ]);
    } catch (error) {
        console.error(error);
        res.status(500).send('Error processing file');
    }
});

const PORT = process.env.PORT || 28508;
app.listen(PORT, () => {
    console.log(`Listening on port ${PORT}`);
});
