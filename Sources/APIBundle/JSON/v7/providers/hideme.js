// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: MIT

function getInfrastructure(module, headers) {
    const providerId = "hideme";
    const openVPN = {
        moduleType: "OpenVPN",
        presetIds: {
            recommended: "default"
        }
    };

    const json = api.getJSON("https://api.hide.me/v1/external/passepartout", headers);
    if (!json.response) {
        return json;
    }

    const entries = [];
    json.response.forEach((server) => {
        entries.push({
            hostname: server.hostname,
            country: server.flag.toUpperCase(),
            tags: server.tags,
        });

        if (!server.children) return;

        server.children.forEach((city) => {
            entries.push({
                hostname: city.hostname,
                country: city.flag.toUpperCase(),
                area: city.displayName,
                tags: server.tags,
            });
        });
    });

    const servers = [];
    entries.forEach((entry) => {
        const hostname = entry.hostname;
        const id = hostname.split(".")[0];
        const country = entry.country;

        const server = {
            serverId: id,
            hostname: hostname,
            supportedModuleTypes: [openVPN.moduleType]
        };

        const metadata = {
            providerId: providerId,
            countryCode: country
        };

        metadata.categoryName = entry.tags.includes("free") ? "free" : "";
        if (entry.area) {
            metadata.area = entry.area;
        }
        server.metadata = metadata;

        servers.push(server);
    });

    const presets = getOpenVPNPresets(providerId, openVPN.moduleType, openVPN.presetIds);

    return {
        response: {
            presets: presets,
            servers: servers,
            cache: json.cache
        }
    };
}

// MARK: OpenVPN

function getOpenVPNPresets(providerId, moduleType, presetIds) {
    const ca = `
-----BEGIN CERTIFICATE-----
MIIKJDCCBgygAwIBAgIQVc9ekKx5ZIkHcGchmaaVEzANBgkqhkiG9w0BAQ0FADCB
kTELMAkGA1UEBhMCTVkxHDAaBgNVBAgME1dpbGF5YWggUGVyc2VrdXR1YW4xDzAN
BgNVBAcMBkxhYnVhbjEZMBcGA1UECgwQZVZlbnR1cmUgTGltaXRlZDEeMBwGA1UE
CwwVQ2VydGlmaWNhdGUgQXV0aG9yaXR5MRgwFgYDVQQDDA9IaWRlLk1lIFJvb3Qg
Q0EwHhcNMTYwMTE3MjExMDI0WhcNNDYwMTA5MjExMDI0WjCBkTELMAkGA1UEBhMC
TVkxHDAaBgNVBAgME1dpbGF5YWggUGVyc2VrdXR1YW4xDzANBgNVBAcMBkxhYnVh
bjEZMBcGA1UECgwQZVZlbnR1cmUgTGltaXRlZDEeMBwGA1UECwwVQ2VydGlmaWNh
dGUgQXV0aG9yaXR5MRgwFgYDVQQDDA9IaWRlLk1lIFJvb3QgQ0EwggQiMA0GCSqG
SIb3DQEBAQUAA4IEDwAwggQKAoIEAQDX8zVTP6FQ4gJ+4e06bxvxifNHK8ht0RZn
zCNrrwkekpB4ojXDghNfS38oK80RfygC8LXN7SnLv+0xw5dRZ3QVIZJnd/DtX2EF
ZVxMyccJkLj8IEZv4Yx7zPnKI9EcQwo64O7npz28JZAGwexmK1W7ohm9VaAAtUPY
6Ej7k/wsJi2d5BeHzYRrfJX3nEft8hbotwsFLPsngDciS3yE2B5zH/PJOZ5uzr/5
djAbeFktfHR6ywbxE2CYjz2pVUfqvzjzwNj5BJPp3K5iTL/oL1xrAkQ5xSPtHbP0
ZCMmR//PC73cqkI6bAw8YAjvq0CG7wSC3rCfzgz3RGGPHMVUmB+GGu1KZoGisexm
9Y3ovmgubM+eE23aMBObf6tcRp1hSv7+EenlqAbyqQ5JqltWgsjEcV6THRKFmlSS
CP84kZK+nLnoto6MEG8sK9d02+iYWPQbVQ9X7O6pMHgVj7vnOLuW6i+hKT/pcsnU
8yhu2495Q07NDAAeX12dMbHhfLAs+DMtxjkj9SxejCS3Gi/XxON0E1NVVNEcl4yu
TODIJVfh/+uDdUn6v8tP7XmIFlKlfyQzfxND/VlRAep1Tt4i04KAhW0SG5/qaXoP
YROoP7eA0igKI5PxGbUZw/ym0i+1iXHR5XqfavZRM6gpOlDH2D9Mo64JfJTWT8J0
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
K127pRfgZn0=
-----END CERTIFICATE----
`;

    const tlsAuthKey = `
8d25d82e75abbcdd73fb17b2ba5d1af2
2d0e026ac8608ec8e51ecb0b3b1b5dba
8ac1f6e556e4b4e3545e979dd26e2d9d
5bc28c1d75b4e37531aabf5da3cba671
1f8998eb66aa290daab6122bdfcb1aa3
b9b428e722ea6e7edd9b878a5161c555
14e6233d18b5cc34e859ecb5852b34ed
6e539d64676edf9ad79470795ae73184
05d93554de1063aec1df6420709c2dcc
79511fa9c5e82de09d560f7d92001ea2
75e4b3e9b6ce19687968b4813d6a9d61
a48311658de88d651edb4eab447d73f6
b209d144a3343a2c992b09c7501cad77
cdf5c6b3be5f9919854bb10182c86794
9df929173b8e98aeea9ffe277eddd7f7
936232e1e44c9feb7a3a2753ed05c90b
`;

    const tlsWrap = api.openVPNTLSWrap("crypt", tlsAuthKey);

    const cfg = {
        ca: ca,
        cipher: "AES-256-CBC",
        digest: "SHA256",
        compressionFraming: 0,
        tlsWrap: tlsWrap,
        renegotiatesAfter: 900,
        checksEKU: true,
    };

    const recommended = {
        providerId: providerId,
        presetId: presetIds.recommended,
        description: "Default",
        moduleType: moduleType,
        templateData: api.jsonToBase64({
            configuration: cfg,
            endpoints: [
                "UDP:3000", "UDP:3010", "UDP:3020", "UDP:3030", "UDP:3040", "UDP:3050",
                "UDP:3060", "UDP:3070", "UDP:3080", "UDP:3090", "UDP:3100",
                "TCP:3000", "TCP:3010", "TCP:3020", "TCP:3030", "TCP:3040", "TCP:3050",
                "TCP:3060", "TCP:3070", "TCP:3080", "TCP:3090", "TCP:3100",
            ]
        })
    };

    return [recommended];
}
