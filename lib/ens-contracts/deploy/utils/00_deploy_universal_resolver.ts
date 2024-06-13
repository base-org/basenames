import { ethers } from 'hardhat'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments } = hre
  const { deploy } = deployments
  const { deployer, owner } = await getNamedAccounts()

  const registry = await ethers.getContract('ENSRegistry')
  const batchGatewayURLs = JSON.parse(process.env.BATCH_GATEWAY_URLS || '[]')

  if (batchGatewayURLs.length === 0) {
    throw new Error('UniversalResolver: No batch gateway URLs provided')
  }

  await deploy('UniversalResolver', {
    from: deployer,
    args: [registry.address, batchGatewayURLs],
    log: true,
  })

  if (owner !== undefined && owner !== deployer) {
    const UR = await ethers.getContract('UniversalResolver')
    const tx = await UR.transferOwnership(owner)
    console.log(`Transfer ownership to ${owner} (tx: ${tx.hash})...`)
    await tx.wait()
  }
}

func.id = 'universal-resolver'
func.tags = ['utils', 'UniversalResolver']
func.dependencies = ['registry']

export default func
