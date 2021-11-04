import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts} = hre;
  const {deploy} = deployments;

  const {deployer} = await getNamedAccounts();

  await deploy('TimeLockWallet', {
    contract: 'TimeLockWallet',
    from: deployer,
    args: ['TimeLockWallet', 'v1'],
    log: true,
  });
};
export default func;
func.tags = ['TimeLockWallet'];
