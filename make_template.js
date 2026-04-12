const fs = require('fs');
const data = JSON.parse(fs.readFileSync('template.json', 'utf8'));
const props = data.properties;

// Remove preemptible scheduling bounds globally natively correctly
delete props.scheduling;
props.scheduling = {
    provisioningModel: 'STANDARD',
    preemptible: false,
    automaticRestart: true
};

const newTemplate = {
    name: 'sp1-gpu-prover-template-standard',
    properties: props
};

fs.writeFileSync('template-standard.json', JSON.stringify(newTemplate, null, 2));
