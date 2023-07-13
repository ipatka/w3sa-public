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

interface EtherscanSourceCodeResponse {
    status: string
    message: string
    result: EtherscanSourceCodeResult[]
}

async function getSourceCode(apikey: string, address: string): Promise<EtherscanSourceCodeResult> {
    const url = `https://api.etherscan.io/api?module=contract&action=getsourcecode&address=${address}&apikey=${apikey}`
    const res = await axios.get(url)
    const data = res.data as EtherscanSourceCodeResponse
    if (!(data.status === '1')) throw new Error(`Failed to get code for ${address}`)
    return data.result[0]
}

async function getDeploymentBlock(provider: ethers.providers.JsonRpcProvider, apikey: string, address: string): Promise<number | undefined> {
    const url = `https://api.etherscan.io/api?module=contract&action=getcontractcreation&contractaddresses=${address}&apikey=${apikey}`
    const res = await axios.get(url)
    if (!(res?.data.status === '1')) throw new Error(`Failed for ${address}`)
    const deploymentTx = res.data.result[0].txHash
    console.log({ deploymentTx })

    const tx = await provider.getTransaction(deploymentTx)
    const deploymentBlock = tx.blockNumber
    return deploymentBlock
}

const main = async () => {
    console.log('running')
    const outdir = '/tmp'
    const apikey = process.env.ETHERSCAN_API_KEY
    const mainnetRpc = process.env.MAINNET
    if (!mainnetRpc || !apikey) throw new Error('MISSING ENV')
    const provider = new ethers.providers.JsonRpcProvider({
        url: mainnetRpc,
    })

    const deployments: {
        name: string
        address: string
        deploymentBlock: number
        sourceCode: EtherscanSourceCodeResult
    }[] = []

    const coreContracts = ['DAI', 'CUSDC', 'USDC', 'COMP', 'WETH', 'WBTC', 'LINK']
    // const coreContracts = ['DAI', 'CUSDC']
    const prefixes = ['PRICE_FEED_', 'VALIDATOR']
    const otherContracts = ['UNISWAP', 'VALIDATOR', 'AAVE_POOL']

    for (const contract of coreContracts) {
        const address = process.env[contract]
        if (!address) {
            console.log(`Missing address for ${contract}`)
            continue
        }
        const deploymentBlock = await getDeploymentBlock(provider, apikey, address)
        if (!deploymentBlock) {
            console.log(`Missing block for ${contract}`)
            continue
        }
        const sourceCode = await getSourceCode(apikey, address)

        const deployment = {
            name: sourceCode.ContractName,
            address,
            deploymentBlock,
            sourceCode,
        }
        deployments.push(deployment)

        if (sourceCode.Proxy === '1') {
            console.log('PROXY DETECTED')
            const proxyAddress = sourceCode.Implementation
            const proxyDeploymentBlock = await getDeploymentBlock(provider, apikey, proxyAddress)
            if (!proxyDeploymentBlock) {
                console.log(`Missing block for ${contract}`)
                continue
            }
            const proxySourceCode = await getSourceCode(apikey, proxyAddress)

            const deployment = {
                name: proxySourceCode.ContractName,
                address: proxyAddress,
                deploymentBlock: proxyDeploymentBlock,
                sourceCode: proxySourceCode,
            }
            deployments.push(deployment)
        }
    }
    let blockRanges = deployments.reduce(
        (cum, curr) => cum.concat(`${curr.deploymentBlock.toString()}..${(curr.deploymentBlock + 1).toString()},`),
        ''
    )
    blockRanges = blockRanges.slice(0, -1)
    console.log({ blockRanges })
    await writeFileSync(path.join(outdir, 'deploymentsWithProxy.json'), JSON.stringify(deployments))
    await writeFileSync(path.join(outdir, 'blockrangesWithProxy.txt'), blockRanges)
}

main()
