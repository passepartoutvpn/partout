//
//  APIV6Mapper+Engine.swift
//  Partout
//
//  Created by Davide De Rosa on 3/27/25.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Partout.
//
//  Partout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Partout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Partout.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import PartoutAPI
import PartoutCore
import PartoutPlatform

extension API.V6.Mapper {
    public convenience init(baseURL: URL, infrastructureURL: ((ProviderID) -> URL)? = nil) {
        self.init(baseURL: baseURL, infrastructureURL: infrastructureURL) {
            API.V6.DefaultScriptExecutor(resultURL: $0, cache: $1, timeout: $2)
        }
    }
}

extension API.V6 {
    final class DefaultScriptExecutor: APIEngine.ScriptExecutor {

        // override the URL for getText/getJSON
        private let resultURL: URL?

        private let cache: ProviderCache?

        private let timeout: TimeInterval

        private let engine: JavaScriptEngine

        init(resultURL: URL?, cache: ProviderCache?, timeout: TimeInterval) {
            self.resultURL = resultURL
            self.cache = cache
            self.timeout = timeout
            engine = JavaScriptEngine()

            engine.inject("getText", object: getText as @convention(block) (String) -> Any?)
            engine.inject("getJSON", object: getJSON as @convention(block) (String) -> Any?)
            engine.inject("jsonToBase64", object: jsonToBase64 as @convention(block) (Any) -> String?)
            engine.inject("ipV4ToBase64", object: ipV4ToBase64 as @convention(block) (String) -> String?)
            engine.inject("openVPNTLSWrap", object: openVPNTLSWrap as @convention(block) (String, String) -> [String: Any]?)
            engine.inject("debug", object: debug as @convention(block) (String) -> Void)
        }

        func fetchInfrastructure(with script: String) async throws -> ProviderInfrastructure {
            let result = try await engine.execute(
                "JSON.stringify(getInfrastructure())",
                after: script,
                returning: APIEngine.ScriptResult<ProviderInfrastructure>.self
            )
            guard let response = result.response else {
                switch result.error {
                case .cached:
                    throw PartoutError(.cached)
                default:
                    throw PartoutError(.scriptException, result.error?.rawValue ?? "unknown")
                }
            }
            return response
        }
    }
}

private extension API.V6.DefaultScriptExecutor {
    func getResult(urlString: String) -> APIEngine.GetResult {
        pp_log(.api, .info, "JS.getResult: Execute with URL: \(resultURL?.absoluteString ?? urlString)")
        guard let url = resultURL ?? URL(string: urlString) else {
            return APIEngine.GetResult(.url)
        }

        // use external caching (e.g. Core Data)
        let cfg: URLSessionConfiguration = .ephemeral
        cfg.timeoutIntervalForRequest = timeout
        let session = URLSession(configuration: cfg)

        var request = URLRequest(url: url)
        if let lastUpdate = cache?.lastUpdate {
            request.setValue(lastUpdate.toRFC1123(), forHTTPHeaderField: "If-Modified-Since")
        }
        if let tag = cache?.tag {
            request.setValue(tag, forHTTPHeaderField: "If-None-Match")
        }

        pp_log(.api, .info, "JS.getResult: GET \(url)")
        if let headers = request.allHTTPHeaderFields {
            pp_log(.api, .info, "JS.getResult: Headers: \(headers)")
        }

        let semaphore = DispatchSemaphore(value: 0)
        var textData: Data?
        var lastModified: Date?
        var tag: String?
        var isCached = false
        let task = session.dataTask(with: request) { data, response, error in
            if let error {
                pp_log(.api, .error, "JS.getResult: Unable to execute: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                let lastModifiedHeader = httpResponse.value(forHTTPHeaderField: "last-modified")
                tag = httpResponse.value(forHTTPHeaderField: "etag")

                pp_log(.api, .debug, "JS.getResult: Response: \(httpResponse)")
                pp_log(.api, .info, "JS.getResult: HTTP \(httpResponse.statusCode)")
                if let lastModifiedHeader {
                    pp_log(.api, .info, "JS.getResult: Last-Modified: \(lastModifiedHeader)")
                    lastModified = lastModifiedHeader.fromRFC1123()
                }
                if let tag {
                    pp_log(.api, .info, "JS.getResult: ETag: \(tag)")
                }
                isCached = httpResponse.statusCode == 304
            }
            textData = data
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()

        guard let textData else {
            pp_log(.api, .error, "JS.getResult: Empty response")
            return APIEngine.GetResult(.network)
        }
        pp_log(.api, .info, "JS.getResult: Success (cached: \(isCached))")
        return APIEngine.GetResult(
            textData,
            lastModified: lastModified,
            tag: tag,
            isCached: isCached
        )
    }

    func getText(urlString: String) -> [String: Any] {
        let textResult = {
            let result = getResult(urlString: urlString)
            if result.isCached {
                return APIEngine.GetResult(.cached)
            }
            guard let text = result.response as? Data else {
                pp_log(.api, .error, "JS.getText: Response is not Data")
                return APIEngine.GetResult(.network)
            }
            guard let string = String(data: text, encoding: .utf8) else {
                pp_log(.api, .error, "JS.getText: Response is not String")
                return APIEngine.GetResult(.network)
            }
            return result.with(response: string)
        }()
        return textResult.serialized()
    }

    func getJSON(urlString: String) -> [String: Any] {
        let jsonResult = {
            let result = getResult(urlString: urlString)
            if result.isCached {
                return APIEngine.GetResult(.cached)
            }
            guard let text = result.response as? Data else {
                pp_log(.api, .error, "JS.getJSON: Response is not Data")
                return APIEngine.GetResult(.network)
            }
            do {
                let object = try JSONSerialization.jsonObject(with: text)
                return result.with(response: object)
            } catch {
                pp_log(.api, .error, "JS.getJSON: Unable to parse JSON: \(error)")
                return APIEngine.GetResult(.parsing)
            }
        }()
        return jsonResult.serialized()
    }

    func jsonToBase64(object: Any) -> String? {
        do {
            return try JSONSerialization.data(withJSONObject: object)
                .base64EncodedString()
        } catch {
            pp_log(.api, .error, "JS.jsonToBase64: Unable to serialize: \(error)")
            return nil
        }
    }

    func ipV4ToBase64(ip: String) -> String? {
        let bytes = ip
            .split(separator: ".")
            .compactMap {
                UInt8($0)
            }
        guard bytes.count == 4 else {
            pp_log(.api, .error, "JS.ipV4ToBase64: Not a IPv4 string")
            return nil
        }
        return Data(bytes)
            .base64EncodedString()
    }

    func openVPNTLSWrap(strategy: String, file: String) -> [String: Any]? {
        let hex = file
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n")
            .joined()
        let key = Data(hex: hex)
        guard key.count == 256 else {
            pp_log(.api, .error, "JS.openVPNTLSWrap: Static key must be 64 bytes long")
            return nil
        }
        return [
            "strategy": strategy,
            "key": [
                "dir": 1,
                "data": key.base64EncodedString()
            ]
        ]
    }

    func debug(message: String) {
        pp_log(.api, .debug, message)
    }
}
