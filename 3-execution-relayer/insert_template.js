const fs = require('fs');
const compute = require('@google-cloud/compute');
const { OAuth2Client } = require('google-auth-library');
const { execSync } = require('child_process');

async function main() {
    const token = execSync('gcloud auth print-access-token', { encoding: 'utf-8' }).trim();
    const oauth2Client = new OAuth2Client();
    oauth2Client.setCredentials({ access_token: token });

    const client = new compute.InstanceTemplatesClient({ authClient: oauth2Client });

    const data = JSON.parse(fs.readFileSync('../template-standard.json', 'utf8'));

    const project = 'total-velocity-493022-f0';
    console.log("Inserting dynamically...");
    const [response] = await client.insert({
        project,
        instanceTemplateResource: data
    });
    console.log("Success:", response.latestResponse.name);
}
main().catch(console.error);
