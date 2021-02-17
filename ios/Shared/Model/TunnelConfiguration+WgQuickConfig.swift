// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import Foundation

extension TunnelConfiguration {

    enum ParserState {
        case inInterfaceSection
        case inPeerSection
        case notInASection
    }

    enum ParseError: Error {
        case invalidLine(String.SubSequence)
        case noInterface
        case multipleInterfaces
        case interfaceHasNoPrivateKey
        case interfaceHasInvalidPrivateKey(String)
        case interfaceHasInvalidListenPort(String)
        case interfaceHasInvalidAddress(String)
        case interfaceHasInvalidDNS(String)
        case interfaceHasInvalidMTU(String)
        case interfaceHasUnrecognizedKey(String)
        case peerHasNoPublicKey
        case peerHasInvalidPublicKey(String)
        case peerHasInvalidPreSharedKey(String)
        case peerHasInvalidAllowedIP(String)
        case peerHasInvalidEndpoint(String)
        case peerHasInvalidPersistentKeepAlive(String)
        case peerHasInvalidTransferBytes(String)
        case peerHasInvalidLastHandshakeTime(String)
        case peerHasUnrecognizedKey(String)
        case multiplePeersWithSamePublicKey
        case multipleEntriesForKey(String)
    }

    convenience init(fromWgQuickConfig wgQuickConfig: String, called name: String? = nil) throws {
        var interfaceConfiguration: InterfaceConfiguration?
        var peerConfigurations = [PeerConfiguration]()

        let lines = wgQuickConfig.split(separator: "\n")

        var parserState = ParserState.notInASection
        var attributes = [String: String]()

        for (lineIndex, line) in lines.enumerated() {
            var trimmedLine: String
            if let commentRange = line.range(of: "#") {
                trimmedLine = String(line[..<commentRange.lowerBound])
            } else {
                trimmedLine = String(line)
            }

            trimmedLine = trimmedLine.trimmingCharacters(in: .whitespaces)
            let lowercasedLine = trimmedLine.lowercased()

            if !trimmedLine.isEmpty {
                if let equalsIndex = trimmedLine.firstIndex(of: "=") {
                    // Line contains an attribute
                    let keyWithCase = trimmedLine[..<equalsIndex].trimmingCharacters(in: .whitespaces)
                    let key = keyWithCase.lowercased()
                    let value = trimmedLine[trimmedLine.index(equalsIndex, offsetBy: 1)...].trimmingCharacters(in: .whitespaces)
                    let keysWithMultipleEntriesAllowed: Set<String> = ["address", "allowedips", "dns"]
                    if let presentValue = attributes[key] {
                        if keysWithMultipleEntriesAllowed.contains(key) {
                            attributes[key] = presentValue + "," + value
                        } else {
                            throw ParseError.multipleEntriesForKey(keyWithCase)
                        }
                    } else {
                        attributes[key] = value
                    }
                    let interfaceSectionKeys: Set<String> = ["privatekey", "listenport", "address", "dns", "mtu"]
                    let peerSectionKeys: Set<String> = ["publickey", "presharedkey", "allowedips", "endpoint", "persistentkeepalive"]
                    if parserState == .inInterfaceSection {
                        guard interfaceSectionKeys.contains(key) else {
                            throw ParseError.interfaceHasUnrecognizedKey(keyWithCase)
                        }
                    } else if parserState == .inPeerSection {
                        guard peerSectionKeys.contains(key) else {
                            throw ParseError.peerHasUnrecognizedKey(keyWithCase)
                        }
                    }
                } else if lowercasedLine != "[interface]" && lowercasedLine != "[peer]" {
                    throw ParseError.invalidLine(line)
                }
            }

            let isLastLine = lineIndex == lines.count - 1

            if isLastLine || lowercasedLine == "[interface]" || lowercasedLine == "[peer]" {
                // Previous section has ended; process the attributes collected so far
                if parserState == .inInterfaceSection {
                    let interface = try TunnelConfiguration.collate(interfaceAttributes: attributes)
                    guard interfaceConfiguration == nil else { throw ParseError.multipleInterfaces }
                    interfaceConfiguration = interface
                } else if parserState == .inPeerSection {
                    let peer = try TunnelConfiguration.collate(peerAttributes: attributes)
                    peerConfigurations.append(peer)
                }
            }

            if lowercasedLine == "[interface]" {
                parserState = .inInterfaceSection
                attributes.removeAll()
            } else if lowercasedLine == "[peer]" {
                parserState = .inPeerSection
                attributes.removeAll()
            }
        }

        let peerPublicKeysArray = peerConfigurations.map { $0.publicKey }
        let peerPublicKeysSet = Set<Data>(peerPublicKeysArray)
        if peerPublicKeysArray.count != peerPublicKeysSet.count {
            throw ParseError.multiplePeersWithSamePublicKey
        }

        if let interfaceConfiguration = interfaceConfiguration {
            self.init(name: name, interface: interfaceConfiguration, peers: peerConfigurations)
        } else {
            throw ParseError.noInterface
        }
    }

    func asWgQuickConfig() -> String {
        var output = "[Interface]\n"
        if let privateKey = interface.privateKey.base64Key() {
            output.append("PrivateKey = \(privateKey)\n")
        }
        if let listenPort = interface.listenPort {
            output.append("ListenPort = \(listenPort)\n")
        }
        if !interface.addresses.isEmpty {
            let addressString = interface.addresses.map { $0.stringRepresentation }.joined(separator: ", ")
            output.append("Address = \(addressString)\n")
        }
        if !interface.dns.isEmpty {
            let dnsString = interface.dns.map { $0.stringRepresentation }.joined(separator: ", ")
            output.append("DNS = \(dnsString)\n")
        }
        if let mtu = interface.mtu {
            output.append("MTU = \(mtu)\n")
        }

        for peer in peers {
            output.append("\n[Peer]\n")
            if let publicKey = peer.publicKey.base64Key() {
                output.append("PublicKey = \(publicKey)\n")
            }
            if let preSharedKey = peer.preSharedKey?.base64Key() {
                output.append("PresharedKey = \(preSharedKey)\n")
            }
            if !peer.allowedIPs.isEmpty {
                let allowedIPsString = peer.allowedIPs.map { $0.stringRepresentation }.joined(separator: ", ")
                output.append("AllowedIPs = \(allowedIPsString)\n")
            }
            if let endpoint = peer.endpoint {
                output.append("Endpoint = \(endpoint.stringRepresentation)\n")
            }
            if let persistentKeepAlive = peer.persistentKeepAlive {
                output.append("PersistentKeepalive = \(persistentKeepAlive)\n")
            }
        }

        return output
    }

    private static func collate(interfaceAttributes attributes: [String: String]) throws -> InterfaceConfiguration {
        guard let privateKeyString = attributes["privatekey"] else {
            throw ParseError.interfaceHasNoPrivateKey
        }
        guard let privateKey = Data(base64Key: privateKeyString), privateKey.count == TunnelConfiguration.keyLength else {
            throw ParseError.interfaceHasInvalidPrivateKey(privateKeyString)
        }
        var interface = InterfaceConfiguration(privateKey: privateKey)
        if let listenPortString = attributes["listenport"] {
            guard let listenPort = UInt16(listenPortString) else {
                throw ParseError.interfaceHasInvalidListenPort(listenPortString)
            }
            interface.listenPort = listenPort
        }
        if let addressesString = attributes["address"] {
            var addresses = [IPAddressRange]()
            for addressString in addressesString.splitToArray(trimmingCharacters: .whitespaces) {
                guard let address = IPAddressRange(from: addressString) else {
                    throw ParseError.interfaceHasInvalidAddress(addressString)
                }
                addresses.append(address)
            }
            interface.addresses = addresses
        }
        if let dnsString = attributes["dns"] {
            var dnsServers = [DNSServer]()
            for dnsServerString in dnsString.splitToArray(trimmingCharacters: .whitespaces) {
                guard let dnsServer = DNSServer(from: dnsServerString) else {
                    throw ParseError.interfaceHasInvalidDNS(dnsServerString)
                }
                dnsServers.append(dnsServer)
            }
            interface.dns = dnsServers
        }
        if let mtuString = attributes["mtu"] {
            guard let mtu = UInt16(mtuString) else {
                throw ParseError.interfaceHasInvalidMTU(mtuString)
            }
            interface.mtu = mtu
        }
        return interface
    }

    private static func collate(peerAttributes attributes: [String: String]) throws -> PeerConfiguration {
        guard let publicKeyString = attributes["publickey"] else {
            throw ParseError.peerHasNoPublicKey
        }
        guard let publicKey = Data(base64Key: publicKeyString), publicKey.count == TunnelConfiguration.keyLength else {
            throw ParseError.peerHasInvalidPublicKey(publicKeyString)
        }
        var peer = PeerConfiguration(publicKey: publicKey)
        if let preSharedKeyString = attributes["presharedkey"] {
            guard let preSharedKey = Data(base64Key: preSharedKeyString), preSharedKey.count == TunnelConfiguration.keyLength else {
                throw ParseError.peerHasInvalidPreSharedKey(preSharedKeyString)
            }
            peer.preSharedKey = preSharedKey
        }
        if let allowedIPsString = attributes["allowedips"] {
            var allowedIPs = [IPAddressRange]()
            for allowedIPString in allowedIPsString.splitToArray(trimmingCharacters: .whitespacesAndNewlines) {
                guard let allowedIP = IPAddressRange(from: allowedIPString) else {
                    throw ParseError.peerHasInvalidAllowedIP(allowedIPString)
                }
                allowedIPs.append(allowedIP)
            }
            peer.allowedIPs = allowedIPs
        }
        if let endpointString = attributes["endpoint"] {
            guard let endpoint = Endpoint(from: endpointString) else {
                throw ParseError.peerHasInvalidEndpoint(endpointString)
            }
            peer.endpoint = endpoint
        }
        if let persistentKeepAliveString = attributes["persistentkeepalive"] {
            guard let persistentKeepAlive = UInt16(persistentKeepAliveString) else {
                throw ParseError.peerHasInvalidPersistentKeepAlive(persistentKeepAliveString)
            }
            peer.persistentKeepAlive = persistentKeepAlive
        }
        return peer
    }

}
