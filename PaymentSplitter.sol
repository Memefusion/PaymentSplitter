// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaymentSplitter is Ownable {
    using SafeERC20 for IERC20;
    uint256 public rate;
    address public collectionAddress;

    constructor(uint256 _rate, address _collectionAddress, address initialOwner) Ownable(initialOwner) {
        rate = _rate;
        collectionAddress = _collectionAddress;
    }

    function changeRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    function changeCollectionAddress(
        address _collectionAddress
    ) external onlyOwner {
        collectionAddress = _collectionAddress;
    }

    function receiveETH(address receiveAddress) external payable returns (bool) {
        uint256 amount = msg.value * rate / 100;
        sendValue(payable(receiveAddress), amount);
        return true;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }
    function receiveERC20(
        uint256 amount,
        address tokenAddress,
        address receiveAddress
    ) external  returns (bool) {
        uint256 ourAllowance = IERC20(tokenAddress).allowance(
            _msgSender(),
            address(this)
        );
        require(amount <= ourAllowance, "Not enough allowance");
        uint256 payAmount = amount * rate /100;

        (bool success, ) = address(tokenAddress).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                receiveAddress,
                payAmount
            )
        );
        require(success, "Token payment to receiveAddress failed");
        (bool success1, ) = address(tokenAddress).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _msgSender(),
                collectionAddress,
                amount-payAmount
            )
        );
        require(success1, "Token payment to receiveAddress failed");
        return true;
    }

    // owner can withdraw ETH after people get tokens
    function withdrawETH() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        (bool success, ) = collectionAddress.call{value: ethBalance}("");
        require(success, "Withdrawal was not successful");
    }
}
