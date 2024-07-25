// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {console2} from "forge-std/console2.sol";
import {PoolModifyLiquidityTest} from "v4-core/test/PoolModifyLiquidityTest.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import "v4-core/types/Currency.sol";
import "../src/ZKTUniswapV4ComplianceHook.sol";
import {IComplianceVersionedMerkleTreeStub} from "@zktnetwork/v0.2/interfaces/IComplianceVersionedMerkleTreeStub.sol";

contract ZKTUniswapV4MerkleTreeHookTest is Test {

    struct Value {
        address party;
        uint256 labels;
        uint256 score;
        uint256 version;
    }

    struct MerkleTreeLeaf {
        Value value;
        uint256 treeIndex;
    }

    struct MerkleTreeData {
        string format;
        string[] leafEncoding;
        bytes32[] tree;
        MerkleTreeLeaf[] values;
    }

    uint256 sepoliaFork;
    ZKTUniswapV4ComplianceHook hook;
    PoolSwapTest router;

    address constant POOL_MANAGER = address(0x33F048ADeCbBD8608436eF31a09db8001149404B);
    address constant TOKENA = Currency.unwrap(CurrencyLibrary.NATIVE);
    address constant TOKENB = address(0x6BCCF17873Fe200962451E6824090b847DB1ACEb);
    address constant HOOK_ADDRESS = address(0x0208b4e996d262d6E09437d8D4526f17970D3637);
    address constant POOL_SWAP = address(0x92d3117268Bd580a748acbEE73162834443a3A17);
    bytes32 merkleRoot = bytes32(uint256(0x3945ad0e6c226783f821a36cd03582fb50527eb03076c4a8ef696bdb21b80517));

    uint256 deployerPrivateKey;

    function setUp() public {
        // select sepolia fork network for testing
        sepoliaFork = vm.createFork("https://sepolia.infura.io/v3/c401b8ee3a324619a453f2b5b2122d7a");
        vm.selectFork(sepoliaFork);

        hook = ZKTUniswapV4ComplianceHook(HOOK_ADDRESS);
        router = new PoolSwapTest(IPoolManager(POOL_MANAGER));
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    }

    function readFromJson() public view returns (MerkleTreeData memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/static/merkleTreeData.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        MerkleTreeData memory merkleTreeData = abi.decode(data, (MerkleTreeData));
        return merkleTreeData;
    }

    function testBeforeSwapHook() public {
        assertNotEq(address(hook), address(0));
        address token0 = uint160(TOKENA) < uint160(TOKENB) ? TOKENA : TOKENB;
        address token1 = uint160(TOKENA) < uint160(TOKENB) ? TOKENB : TOKENA;

        bytes32[] memory proof = new bytes32[](7);
        proof[0] = bytes32(uint256(0xf34afc99c4dff0e0d5b73afd059d02f91a02429db5e31c30c7fc17d264e78b0e));
        proof[1] = bytes32(uint256(0x2ae44eb19fdf06d56905969c377168413323299bc5b843bc3ece370e7e249611));
        proof[2] = bytes32(uint256(0x7d46593bdc363ed82bfbf7afbe7f750cfffd11af67366d12a2afda97140562bc));
        proof[3] = bytes32(uint256(0x0642c887269ab02786515a3aa28705e08391a3bad41f63679938b901aa8598a9));
        proof[4] = bytes32(uint256(0x84a4ccd9a6a031bf0a3923a1acfdfd5101685477da587d2606ef53cb27848579));
        proof[5] = bytes32(uint256(0x02777876d4c8e66fdc8792dabc76573914b000755ba8f3c417427b2edd1200bc));
        proof[6] = bytes32(uint256(0x90ab34a32c6701b3403045dc928f5d1add5b2bfd45a4990f6d6add8ac91ef77f));

        // use wrong address for party
        address party = vm.addr(deployerPrivateKey);
        uint256 labels = 5;
        uint256 score = 72;
        uint256 version = 1;

        bytes memory subEncodedData = abi.encode(party, labels, score, version);
        bytes memory encodedData = abi.encode(merkleRoot, subEncodedData);
        bytes memory hookData = abi.encode(proof, encodedData);

        int24 tickSpacing = 60;
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 50000,
            tickSpacing: tickSpacing,
            hooks: IHooks(HOOK_ADDRESS)
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: 200 ether,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO * 100
        });

        PoolSwapTest.TestSettings memory testSettings =
                            PoolSwapTest.TestSettings({withdrawTokens: true, settleUsingTransfer: true, currencyAlreadySent: false});

        /// test revert
        vm.startPrank(vm.addr(deployerPrivateKey));
        IERC20(token1).approve(address(router), type(uint256).max);
        vm.expectRevert(bytes("ZKTUniswapV4ComplianceHook: Invalid proof"));
        router.swap{value:  0.01 ether}(key, params, testSettings, hookData);
        vm.stopPrank();

        ///
        party = 0xcdD7993EF96cE46b59A93ef551ba2Ee8a43AC235;
        payable(party).transfer(0.01 ether);
        subEncodedData = abi.encode(party, labels, score, version);
        encodedData = abi.encode(merkleRoot, subEncodedData);
        hookData = abi.encode(proof, encodedData);
        vm.stopPrank();

        /// test pass
        vm.startPrank(vm.addr(deployerPrivateKey));
        IERC20(token1).approve(address(router), type(uint256).max);
        router.swap{value:  0.01 ether}(key, params, testSettings, hookData);
        vm.stopPrank();
    }

    function testHookVerify() public view {
        bytes32[] memory proof = new bytes32[](7);
        proof[0] = bytes32(uint256(0xf34afc99c4dff0e0d5b73afd059d02f91a02429db5e31c30c7fc17d264e78b0e));
        proof[1] = bytes32(uint256(0x2ae44eb19fdf06d56905969c377168413323299bc5b843bc3ece370e7e249611));
        proof[2] = bytes32(uint256(0x7d46593bdc363ed82bfbf7afbe7f750cfffd11af67366d12a2afda97140562bc));
        proof[3] = bytes32(uint256(0x0642c887269ab02786515a3aa28705e08391a3bad41f63679938b901aa8598a9));
        proof[4] = bytes32(uint256(0x84a4ccd9a6a031bf0a3923a1acfdfd5101685477da587d2606ef53cb27848579));
        proof[5] = bytes32(uint256(0x02777876d4c8e66fdc8792dabc76573914b000755ba8f3c417427b2edd1200bc));
        proof[6] = bytes32(uint256(0x90ab34a32c6701b3403045dc928f5d1add5b2bfd45a4990f6d6add8ac91ef77f));
        address party = 0xcdD7993EF96cE46b59A93ef551ba2Ee8a43AC235;
        uint256 labels = 5;
        uint256 score = 72;
        uint256 version = 1;

        bytes memory subEncodedData = abi.encode(party, labels, score, version);
        bytes memory encodedData = abi.encode(merkleRoot, subEncodedData);
        console2.logBytes(encodedData);

        IComplianceVersionedMerkleTreeStub stub = IComplianceVersionedMerkleTreeStub(0xAd6a548adF382324fbeFC29d88A7668c9C67EaE7);
        assertEq(stub.verify(proof, encodedData), true, "Verify should be true");
    }
}
