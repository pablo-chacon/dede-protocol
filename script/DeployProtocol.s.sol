// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import "../contracts/ParcelCore.sol";
import "../contracts/Escrow.sol";
import "../contracts/AStarSignerRegistryStaked.sol";

contract DeployProtocol is Script {
  function run() external {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    address protocolTreasury = vm.envAddress("PROTOCOL_TREASURY");
    uint16  protocolBps = uint16(vm.envUint("PROTOCOL_BPS"));
    address stakeToken = vm.envAddress("STAKE_TOKEN");
    uint256 minStake   = vm.envUint("MIN_STAKE");
    address platformTreasury = vm.envAddress("PLATFORM_TREASURY");

    vm.startBroadcast(deployerKey);

    Escrow escrow = new Escrow();
    AStarSignerRegistryStaked reg = new AStarSignerRegistryStaked(stakeToken, minStake);

    ParcelCore core = new ParcelCore(address(escrow), address(reg), protocolTreasury, protocolBps);
    escrow.setParcelCore(address(core));

    // fee schedule: base 3%, tiers at 24/36/48/56h => 6/12/20/22%
    core.setPlatformTreasury(platformTreasury);
    uint64[] memory th = new uint64[](4);
    th[0]=24 hours; th[1]=36 hours; th[2]=48 hours; th[3]=56 hours;
    uint16[] memory bp = new uint16[](4);
    bp[0]=600; bp[1]=1200; bp[2]=2000; bp[3]=2200;
    core.setFeeSchedule(th, bp, 300);
    core.setFinalizeTipBps(5);

    vm.stopBroadcast();

    console2.log("PARCEL_CORE=", address(core));
    console2.log("ESCROW=", address(escrow));
    console2.log("ASTAR_REGISTRY_STAKED=", address(reg));
    console2.log("PROTOCOL_TREASURY=", protocolTreasury);
    console2.log("PROTOCOL_BPS=", protocolBps);
    console2.log("PLATFORM_TREASURY=", platformTreasury);
  }
}
