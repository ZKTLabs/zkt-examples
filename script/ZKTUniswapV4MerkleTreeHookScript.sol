// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import "v4-core/libraries/Hooks.sol";
import {Script} from "forge-std/Script.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import "v4-core/interfaces/IPoolManager.sol";
import {PoolModifyLiquidityTest} from "v4-core/test/PoolModifyLiquidityTest.sol";
import  "v4-core/types/Currency.sol";
import {HookMiner} from "./HookMiner.sol";
import {ZKTUniswapV4ComplianceHook} from "../src/ZKTUniswapV4ComplianceHook.sol";

contract ZKTUniswapV4MerkleTreeHookScript is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
    address constant POOL_MANAGER = address(0x33F048ADeCbBD8608436eF31a09db8001149404B);
    // our compliance stub address
    address constant COMPLIANCE_STUB = address(0xAd6a548adF382324fbeFC29d88A7668c9C67EaE7);

    address HOOK_ADDRESS;
    bytes32 SALT;

    function setUp() public {
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG);
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(ZKTUniswapV4ComplianceHook).creationCode,
            abi.encode(address(COMPLIANCE_STUB), address(POOL_MANAGER), uint256(60))
        );
        HOOK_ADDRESS = hookAddress;
        SALT = salt;
    }

    function run() public {
        vm.broadcast();
        uint256 validScore = 60;
        ZKTUniswapV4ComplianceHook zkt = new ZKTUniswapV4ComplianceHook{salt: SALT}(address(COMPLIANCE_STUB), IPoolManager(address(POOL_MANAGER)), validScore);
        require(address(zkt) == HOOK_ADDRESS, "ZKTUniswapV4ComplianceHook: hook address mismatch");
    }
}

contract ZKTUniswapV4MerkleTreeHookPoolScript is Script {

    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
//    address constant HOOK_ADDRESS = address(0x020694883742262E0b6b6601857412fE939b18B8);
//    address constant HOOK_ADDRESS = address(0x02075310C86150Cb92819E4F2AA30D747D98a347);
    address constant HOOK_ADDRESS = address(0x0208b4e996d262d6E09437d8D4526f17970D3637);
    address constant TOKENA = Currency.unwrap(CurrencyLibrary.NATIVE);
    address constant TOKENB = address(0x6BCCF17873Fe200962451E6824090b847DB1ACEb);

    IPoolManager manager = IPoolManager(0x33F048ADeCbBD8608436eF31a09db8001149404B);
    PoolModifyLiquidityTest router = PoolModifyLiquidityTest(0x49e9cC8160410a9D8Be588f2fC9F7642e4e6E995);
    uint256 deployerPrivateKey;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    }

    function initialize() internal {
        /// sort token and ready to create_pool
        address token0 = uint160(TOKENA) < uint160(TOKENB) ? TOKENA : TOKENB;
        address token1 = uint160(TOKENA) < uint160(TOKENB) ? TOKENB : TOKENA;

        int24 tickSpacing = 60;
        /// floor(sqrt(1) * 2 ^ 96)  == 1
//        uint160 initializePrice = 79228162514264337593543950336;
        /// floor(sqrt(50000 / 1) * 2 ^ 96)
        uint160 initializePrice = 17715955711429571029610171616072;
//        uint160 initializePrice = 5602277097478614198912276234240;
        bytes memory hookData = new bytes(0);

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 50000,
            tickSpacing: tickSpacing,
            hooks: IHooks(HOOK_ADDRESS)
        });
        vm.startBroadcast(deployerPrivateKey);
        manager.initialize(pool, initializePrice, hookData);
        vm.stopBroadcast();
    }

    function modifyLiquidity() internal {
        /// sort token and ready to create_pool
        address token0 = uint160(TOKENA) < uint160(TOKENB) ? TOKENA : TOKENB;
        address token1 = uint160(TOKENA) < uint160(TOKENB) ? TOKENB : TOKENA;

        int24 tickSpacing = 60;
        bytes memory hookData = new bytes(0);

        PoolKey memory pool = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 50000,
            tickSpacing: tickSpacing,
            hooks: IHooks(HOOK_ADDRESS)
        });

        // add liquidity
//        vm.broadcast();
//        IERC20(token0).approve(address(router), type(uint256).max);
        vm.startBroadcast(deployerPrivateKey);
        IERC20(token1).approve(address(router), type(uint256).max);
        router.modifyLiquidity{value: 1 ether}(pool, IPoolManager.ModifyLiquidityParams(108180, 108240, 100000e18), hookData);
        vm.stopBroadcast();
    }

    function run() public {
        initialize();
        modifyLiquidity();
    }
}