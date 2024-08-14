var exec = require('child_process').exec;
let express = require('express')
const multer = require("multer");
const fileUpload = require("express-fileupload")
var bodyParser = require('body-parser')
const fs = require("fs")
const app = express()
//app.use(fileUpload());
app.use(
    bodyParser.raw({limit: "50mb", type: ['model/*']})
);
//const upload = multer({ dest: "uploads/" });
//app.use(express.json());
//app.use(express.urlencoded({ extended: true }));


app.get("/", (req, res) => {
    res.send("hello world")
})

app.post("/3d", (req, res) => {
    const type = req.get('Content-Type')
    const ext = type.split("/")[1]
    console.log("ext", ext);
//	console.log(req)
    const b = req.body
    const fileName = "file_" + new Date().toISOString() + "." + ext
    fs.writeFile(fileName, b, "binary", function (err) {
        if (err) {
            console.log(err)
        } else {
            console.log("The file was saved!");
            const { execSync } = require('child_process');

            // Set executable permissions
            execSync('chmod +x ./prusaslicer/prusa-slicer');
            execSync('chmod +x /opt/render/project/src/prusaslicer/bin/bambu-studio');
            const outFile = "out_" + new Date().toISOString() + ".3mf"
            exec(`./prusaslicer/prusa-slicer --slice 0 --debug 2 --export-3mf ${outFile} ${fileName}`, (err, stdout, stderr) => {
                if (err) {
                    console.log(err);
                    return;
                }

                // the *entire* stdout and stderr (buffered)
                console.log(`stdout: ${stdout}`);
                console.log(`stderr: ${stderr}`);
                // Completed:
                res.sendFile(outFile)

            });
        }
    });
})


app.listen(28508, () => {
    console.log("listening on 28508")
})
///
//console.log("h")

