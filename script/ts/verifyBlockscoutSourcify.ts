import { ethers } from 'ethers'
import { readFileSync, writeFileSync, readdirSync } from 'fs'
import path from 'path'
import axios from 'axios'

interface EtherscanSourceCodeResult {
    SourceCode: string
    ABI: string
    ContractName: string
    CompilerVersion: string
    OptimizationUsed: string
    Runs: string
    ConstructorArguments: string
    EVMVersion: string
    Library: string
    LicenseType: string
    Proxy: string
    Implementation: string
    SwarmSource: string
}

interface Deployment {
    name: string
    address: string
    deploymentBlock: number
    sourceCode: EtherscanSourceCodeResult
}

interface BlockscoutVerifyRequest {
    addressHash: string
    name: string
    compilerVersion: string
    optimization: boolean
    contractSourceCode: string
    optimizationRuns?: number
}

const main = async () => {
    console.log('running')
    const deploymentsFile = '/tmp/deployments.json'
    const deploymentsRaw = readFileSync(deploymentsFile, 'utf8')
    const allDeployments = JSON.parse(deploymentsRaw) as Deployment[]
    const url = 'https://securityalliance.dev/api?module=contract&action=verify'
    
    const deployments = allDeployments.filter(d => d.address === '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599')

    for (const deployment of deployments) {
      console.log(`Verifying ${deployment.name} at ${deployment.address}`)
        let blockscoutRequest: BlockscoutVerifyRequest = {
            addressHash: deployment.address,
            name: deployment.sourceCode.ContractName,
            compilerVersion: deployment.sourceCode.CompilerVersion,
            optimization: deployment.sourceCode.OptimizationUsed === '1',
            contractSourceCode: deployment.sourceCode.SourceCode,
        }
        if (blockscoutRequest.optimization) blockscoutRequest = { ...blockscoutRequest, optimizationRuns: parseInt(deployment.sourceCode.Runs) }

        const data = JSON.stringify(blockscoutRequest)
        const res = await axios.post(url, data, {
            headers: {
                'Content-Type': 'application/json',
            },
            params: {},
        })
        console.log({res})
        break
    }
}

main()
