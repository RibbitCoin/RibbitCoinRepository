//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../token/RIBC.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AirdropRIBC is Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 ribc;
    uint256 price = 4e26; 
    mapping(address => bool) isGet;

    event TokenClaimed(uint256 amount, address indexed to);
    constructor(address _tokenaddress) {
        ribc = IERC20(_tokenaddress);
    }


    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }
    function getPrice()view public returns(uint256){
        return price;
    }

    function changeStoppedState(bool stop) public onlyOwner {
        if (stop) {
            _pause();
        } else {
            _unpause();
        }
    }


    function emergencyExit(address to) public nonReentrant onlyOwner {
        ribc.safeTransfer(to, ribc.balanceOf(address(this)));
    }

    function hasGet(address _address) public view returns (bool) {
        return isGet[_address];
    }

    bytes32 root;

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function claim(
        address _address,
        uint256 _amount,
        bytes32[] calldata _proofs
    ) external nonReentrant whenNotPaused{
        require(isGet[_address] == false, "has got");
        bytes32 _leaf = keccak256(abi.encodePacked(_address, _amount));
        bool _verify = MerkleProof.verify(_proofs, root, _leaf);
        require(_verify, "fail");
        isGet[_address] = true;
        uint256 amountAll = _amount * price;
        require(
            amountAll <= ribc.balanceOf(address(this)),
            "Insufficient balance"
        );
        ribc.safeTransfer(_address, amountAll);
    }
}
