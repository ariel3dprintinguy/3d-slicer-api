const exec = require('child_process').exec;
const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path'); // Import path module
const cors = require('cors'); // Import the cors middleware
const app = express();

// Enable CORS for all routes
app.use(cors());


app.use(
    bodyParser.raw({ limit: '50mb', type: ['model/*'] })
);

app.get('/', (req, res) => {
    res.send('hello world');
});

app.post('/3d', (req, res) => {
    const type = req.get('Content-Type');
    const ext = type.split('/')[1];
    console.log('ext', ext);

    const b = req.body;
    const fileName = 'file_' + new Date().toISOString() + '.' + ext;

    fs.writeFile(fileName, b, 'binary', function (err) {
        if (err) {
            console.log(err);
        } else {
            console.log('The file was saved!');
            const { execSync } = require('child_process');

            // Set executable permissions
            execSync('chmod +x ./prusaslicer/prusa-slicer');
            execSync('chmod +x ./prusaslicer/bin/bambu-studio');

            const outFile = 'out_' + new Date().toISOString() + '.3mf';

            exec(./prusaslicer/prusa-slicer --slice 0 --debug 2 --export-3mf ${outFile} ${fileName}, (err, stdout, stderr) => {
                if (err) {
                    console.log(err);
                    return;
                }

                // the *entire* stdout and stderr (buffered)
                console.log(stdout: ${stdout});
                console.log(stderr: ${stderr});

                // Use path.resolve to create an absolute path
                const absoluteOutFilePath = path.resolve(__dirname, outFile);

                // Completed:
                res.sendFile(absoluteOutFilePath, (err) => {
                    if (err) {
                        console.log(err);
                        res.status(err.status).end();
                    }
                });
            });
        }
    });
});

app.listen(28508, () => {
    console.log('listening on 28508');
});
