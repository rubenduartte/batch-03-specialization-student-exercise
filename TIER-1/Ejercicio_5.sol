// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/** CUASI SUBASTA INGLESA
 *
 * Descripción:
 * Tienen la tarea de crear un contrato inteligente que permita crear subastas Inglesas (English auction).
 * Se paga 1 Ether para crear una subasta y se debe especificar su hora de inicio y finalización.
 * Los ofertantes envian sus ofertas a la subasta que ellos deseen durante el tiempo que la subasta esté abierta.
 * Cada subasta tiene un ID único que permite a los ofertantes identificar la subasta a la que desean ofertar.
 * Los ofertantes para poder proponer su oferta envían Ether al contrato (llamando al método 'proponerOferta' o enviando directamente).
 * Las ofertas deben ser mayores a la oferta más alta actual para una subasta en particular.
 * Si se realiza una oferta dentro de los 5 minutos finales de la subasta, el tiempo de finalización se extiende en 5 minutos
 * Una vez que el tiempo de la subasta se cumple, cualquier puede llamar al método 'finalizarSubasta' para finalizar la subasta.
 * Cuando finaliza la subasta, el ganador recupera su oferta y se lleva el 1 Ether depositado por el creador.
 * Cuando finaliza la subasta se emite un evento con el ganador (address)
 * Las personas que no ganaron la subasta pueden recuperar su oferta después de que finalice la subasta
 *
 * ¿Qué es una subasta Inglesa?
 * En una subasta inglesa el precio comienza bajo y los postores pujan el precio haciendo ofertas.
 * Cuando se cierra la subasta, se emite un evento con el mejor postor.
 *
 * Métodos a implementar:
 * - El método 'creaSubasta(uint256 _startTime, uint256 _endTime)':
 *      * Crea un ID único del typo bytes32 para la subasta y lo guarda en la lista de subastas activas
 *      * Permite a cualquier usuario crear una subasta pagando 1 Ether
 *          - Error en caso el usuario no envíe 1 Ether: CantidadIncorrectaEth();
 *      * Verifica que el tiempo de finalización sea mayor al tiempo de inicio
 *          - Error en caso el tiempo de finalización sea mayo al tiempo de inicio: TiempoInvalido();
 *      * Disparar un evento llamado 'SubastaCreada' con el ID de la subasta y el creador de la subasta (address)
 *
 * - El método 'proponerOferta(bytes32 _auctionId)':
 *      * Verifica que ese ID de subasta (_auctionId) exista
 *          - Error si el ID de subasta no existe: SubastaInexistente();
 *      * Usando el ID de una subasta (_auctionId), el ofertante propone una oferta y envía Ether al contrato
 *          - Error si la oferta no es mayor a la oferta más alta actual: OfertaInvalida();
 *      * Solo es llamado durante el tiempo de la subasta (entre el inicio y el final)
 *          - Error si la subasta no está en progreso: FueraDeTiempo();
 *      * Emite el evento 'OfertaPropuesta' con el postor y el monto de la oferta
 *      * Guarda la cantidad de Ether enviado por el postor para luego poder recuperar su oferta en caso no gane la subasta
 *      * Añade 5 minutos al tiempo de finalización de la subasta si la oferta se realizó dentro de los últimos 5 minutos
 *      Nota: Cuando se hace una oferta, incluye el Ether enviado anteriormente por el ofertante
 *
 * - El método 'finalizarSubasta(bytes32 _auctionId)':
 *      * Verifica que ese ID de subasta (_auctionId) exista
 *          - Error si el ID de subasta no existe: SubastaInexistente();
 *      * Es llamado luego del tiempo de finalización de la subasta usando su ID (_auctionId)
 *          - Error si la subasta aún no termina: SubastaEnMarcha();
 *      * Elimina el ID de la subasta (_auctionId) de la lista de subastas activas
 *      * Emite el evento 'SubastaFinalizada' con el ganador de la subasta y el monto de la oferta
 *      * Añade 1 Ether al balance del ganador de la subasta para que éste lo puedo retirar después
 *
 * - El método 'recuperarOferta(bytes32 _auctionId)':
 *      * Permite a los usuarios recuperar su oferta (tanto si ganaron como si perdieron la subasta)
 *      * Verifica que la subasta haya finalizado
 *      * El smart contract le envía el balance de Ether que tiene a favor del ofertante
 *
 * - El método 'verSubastasActivas() returns(bytes32[])':
 *      * Devuelve la lista de subastas activas en un array
 *
 * Para correr el test de este contrato:
 * $ npx hardhat test test/EjercicioTesting_5.js
 */

contract Ejercicio_5 {
    address payable public propietario;


    struct Subasta {
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool status;
    }

    mapping(bytes32 => Subasta) public subastas;
    bytes32[] public arraySubastasAct;
    

    event SubastaCreada(bytes32 indexed idSubasta, address indexed creador);
    event OfertaPropuesta(address indexed postor, uint256 monto);
    event SubastaFinalizada(address indexed ganador, uint256 monto);

  error CantidadIncorrectaEth();
    error TiempoInvalido();
    error SubastaInexistente();
    error FueraDeTiempo();
    error OfertaInvalida();
    error SubastaEnMarcha();

    constructor() {
        propietario = payable(msg.sender);
    }

    function creaSubasta(
        uint256 _startTime,
        uint256 _endTime
    ) external payable {
         if (msg.value != 1 ether) revert CantidadIncorrectaEth();
        if (_endTime <= _startTime) revert TiempoInvalido();

        bytes32 _auctionId = _createId(_startTime, _endTime);

        subastas[_auctionId].startTime = _startTime;
        subastas[_auctionId].endTime = _endTime;
        subastas[_auctionId].status = false;
        subastas[_auctionId].highestBid = 0;
        subastas[_auctionId].highestBidder = address(0);
        arraySubastasAct.push(_auctionId);
        emit SubastaCreada(_auctionId, msg.sender);
    }

    function proponerOferta(bytes32 _auctionId) external payable {

        if (subastas[_auctionId].endTime == 0) revert SubastaInexistente();

        if (block.timestamp >= subastas[_auctionId].endTime) revert FueraDeTiempo();

        if (msg.value <= subastas[_auctionId].highestBid) revert OfertaInvalida();

        // Extiende el tiempo de la subasta si la oferta se realiza dentro de los últimos 5 minutos
        if (block.timestamp >= subastas[_auctionId].endTime - 5 minutes) {
            subastas[_auctionId].endTime += 5 minutes;
        }

    }

        address payable mejorPostorPayable = payable(
            subastas[_auctionId].highestBidder
        );
       // mejorPostorPayable.transfer(subastas[_auctionId].highestBid);

        // Actualiza el mejor postor y la mejor oferta
        subastas[_auctionId].highestBidder = msg.sender;
        subastas[_auctionId].highestBid = msg.value;

        // Emite un evento para registrar la nueva oferta
        emit OfertaPropuesta(msg.sender, msg.value);
    }

    function finalizarSubasta(bytes32 _auctionId) external {
        if (subastas[_auctionId].endTime == 0) revert SubastaInexistente();
        if (block.timestamp < subastas[_auctionId].endTime) revert SubastaEnMarcha();

        subastas[_auctionId].status = true;
        address payable mejorPostorPayable = payable(
            subastas[_auctionId].highestBidder
        );

        if (subastas[_auctionId].highestBidder != address(0)) {
            propietario.transfer(tarifaSubasta);
            mejorPostorPayable.transfer(subastas[_auctionId].highestBid);
            emit SubastaFinalizada(
                subastas[_auctionId].highestBidder,
                subastas[_auctionId].highestBid
            );

        }

    }

    function recuperarOferta(bytes32 _auctionId) external {
        if (subastas[_auctionId].endTime == 0) revert SubastaInexistente();
        if (!subastas[_auctionId].status) revert SubastaEnMarcha();

        address payable postor = payable(msg.sender);
        uint256 montoRecuperado = subastas[_auctionId].highestBid;

        postor.transfer(montoRecuperado);
    }

    function verSubastasActivas() external view returns (bytes32[] memory) {
        return arraySubastasAct;
    }

 function _createId(
        uint256 _startTime,
        uint256 _endTime
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _startTime,
                    _endTime,
                    msg.sender,
                    block.timestamp
                )
            );
    }
}
