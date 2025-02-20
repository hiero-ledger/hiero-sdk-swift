/*
 * ‌
 * Hedera Swift SDK
 * ​
 * Copyright (C) 2023 - 2023 Hedera Hashgraph, LLC
 * ​
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ‍
 */

extension Network {
    internal struct Config {
        internal let map: [AccountId: Int]
        internal let nodes: [AccountId]
        internal let addresses: [Set<String>]
    }
}

extension Network.Config: ExpressibleByDictionaryLiteral {
    internal init(dictionaryLiteral elements: (AccountId, Set<String>)...) {
        var map: [AccountId: Int] = [:]
        var nodes: [AccountId] = []
        var addresses: [Set<String>] = []
        for (index, (key, value)) in elements.enumerated() {
            map[key] = index
            nodes.append(key)
            addresses.append(value)
        }

        self.init(map: map, nodes: nodes, addresses: addresses)
    }
}

extension Network.Config {
    internal static let mainnet: Self = [
        3: ["13.124.142.126", "15.164.44.66", "15.165.118.251", "34.239.82.6", "35.237.200.180"],
        4: ["3.130.52.236", "35.186.191.247"],
        5: ["3.18.18.254", "23.111.186.250", "35.192.2.25", "74.50.117.35", "107.155.64.98"],
        6: ["13.52.108.243", "13.71.90.154", "35.199.161.108", "104.211.205.124"],
        7: ["3.114.54.4", "35.203.82.240"],
        8: ["35.183.66.150", "35.236.5.219"],
        9: ["35.181.158.250", "35.197.192.225"],
        10: ["3.248.27.48", "35.242.233.154", "177.154.62.234"],
        11: ["13.53.119.185", "35.240.118.96"],
        12: ["35.177.162.180", "35.204.86.32", "170.187.184.238"],
        13: ["34.215.192.104", "35.234.132.107"],
        14: ["35.236.2.27", "52.8.21.141"],
        15: ["3.121.238.26", "35.228.11.53"],
        16: ["18.157.223.230", "34.91.181.183"],
        17: ["18.232.251.19", "34.86.212.247"],
        18: ["141.94.175.187"],
        19: ["13.244.166.210", "13.246.51.42", "18.168.4.59", "34.89.87.138"],
        20: ["34.82.78.255", "52.39.162.216"],
        21: ["13.36.123.209", "34.76.140.109"],
        22: ["34.64.141.166", "52.78.202.34"],
        23: ["3.18.91.176", "35.232.244.145", "69.167.169.208"],
        24: ["18.135.7.211", "34.89.103.38"],
        25: ["13.232.240.207", "34.93.112.7"],
        26: ["13.228.103.14", "34.87.150.174"],
        27: ["13.56.4.96", "34.125.200.96"],
        28: ["18.139.47.5", "35.198.220.75"],
        29: ["34.142.71.129", "54.74.60.120", "80.85.70.197"],
        30: ["34.201.177.212", "35.234.249.150"],
        31: ["3.77.94.254", "34.107.78.179"],
    ]

    internal static let testnet: Self = [
        3: ["0.testnet.hedera.com", "34.94.106.61", "50.18.132.211"],
        4: ["1.testnet.hedera.com", "35.237.119.55", "3.212.6.13"],
        5: ["2.testnet.hedera.com", "35.245.27.193", "52.20.18.86"],
        6: ["3.testnet.hedera.com", "34.83.112.116", "54.70.192.33"],
        7: ["4.testnet.hedera.com", "34.94.160.4", "54.176.199.109"],
        8: ["5.testnet.hedera.com", "34.106.102.218", "35.155.49.147"],
        9: ["6.testnet.hedera.com", "34.133.197.230", "52.14.252.207"],
    ]

    internal static let previewnet: Self = [
        3: ["0.previewnet.hedera.com", "35.231.208.148", "3.211.248.172", "40.121.64.48"],
        4: ["1.previewnet.hedera.com", "35.199.15.177", "3.133.213.146", "40.70.11.202"],
        5: ["2.previewnet.hedera.com", "35.225.201.195", "52.15.105.130", "104.43.248.63"],
        6: ["3.previewnet.hedera.com", "35.247.109.135", "54.241.38.1", "13.88.22.47"],
        7: ["4.previewnet.hedera.com", "35.235.65.51", "54.177.51.127", "13.64.170.40"],
        8: ["5.previewnet.hedera.com", "34.106.247.65", "35.83.89.171", "13.78.232.192"],
        9: ["6.previewnet.hedera.com", "34.125.23.49", "50.18.17.93", "20.150.136.89"],
    ]
}
