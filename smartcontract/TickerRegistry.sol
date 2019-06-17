/**
 * Source Code first verified at https://etherscan.io on Tuesday, April 10, 2018
 (UTC) */

pragma solidity ^0.4.21;

// this smart contract is setting a token symbol - ticker
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 이 함수는, 소유주 주소, function을 제어할 수 있는 권한, user permissions에 대해서 간소화 합니다.
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender; //외부에서 지금 함수를 호출한 주소
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ITickerRegistry {
    /**
    * @dev Check the validity of the symbol
    * @param _symbol token symbol
    * @param _owner address of the owner
    * @param _tokenName Name of the token
    * @return bool
    */
    function checkValidity(string _symbol, address _owner, string _tokenName) public returns(bool);

    /**
    * @dev Returns the owner and timestamp for a given symbol
    * @param _symbol symbol
    */
    function getDetails(string _symbol) public view returns (address, uint256, string, bytes32, bool);


}

contract Util {

   /**
    * @dev changes a string to upper case
    * @param _base string to change
    */
    function upper(string _base) internal pure returns (string) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            bytes1 b1 = _baseBytes[i];
            if (b1 >= 0x61 && b1 <= 0x7A) {
                b1 = bytes1(uint8(b1)-32);
            }
            _baseBytes[i] = b1;
        }
        return string(_baseBytes);
    }

}

/*
  Allows issuers to reserve their token symbols ahead of actually generating their security token.
  SecurityTokenRegistry would reference this contract and ensure that a token symbol exists here and
  only its owner can deploy the token with that symbol.
*/






/**
 * @title TickerRegistry
 * @dev Contract used to register the security token symbols
 */

contract TickerRegistry is ITickerRegistry, Ownable, Util {

    using SafeMath for uint256;
    // constant variable to check the validity to use the symbol
    // For now it's value is 90 days;
    uint256 public expiryLimit = 7 * 1 days; //만료기간 기본 7일 설정

    // SecuirtyToken Registry contract address
    address public strAddress;

    // Details of the symbol that get registered with the polymath platform
    struct SymbolDetails {
        address owner;
        uint256 timestamp;
        string tokenName;
        bytes32 swarmHash;
        bool status;
    }

    // Storage of symbols correspond to their details.
    mapping(string => SymbolDetails) registeredSymbols; //string-SymbolDetails로 mapping

    // Emit after the symbol registration
    event LogRegisterTicker(address indexed _owner, string _symbol, string _name, bytes32 _swarmHash, uint256 _timestamp);
    // Emit when the token symbol expiry get changed
    event LogChangeExpiryLimit(uint256 _oldExpiry, uint256 _newExpiry);

    function TickerRegistry() public {

    }

    /**
     * @dev Register the token symbol for its particular owner
            Once the token symbol is registered to its owner then no other issuer can claim
            its ownership. If the symbol expires and its issuer hasn't used it, then someone else can take it.
     * @param _symbol token symbol
     * @param _tokenName Name of the token
     * @param _owner Address of the owner of the token
     * @param _swarmHash Off-chain details of the issuer and token
     */
    function registerTicker(address _owner, string _symbol, string _tokenName, bytes32 _swarmHash) public {
        require(bytes(_symbol).length > 0 && bytes(_symbol).length <= 10);//심볼 길이 제한
        string memory symbol = upper(_symbol);
        require(expiryCheck(symbol));//심볼 만료 검사
        registeredSymbols[symbol] = SymbolDetails(_owner, now, _tokenName, _swarmHash, false);
        emit LogRegisterTicker (_owner, symbol, _tokenName, _swarmHash, now);//해당 이벤트 발생시킴
    }

     /**
      * @dev Change the expiry time for the token symbol
      * @param _newExpiry new time period for token symbol expiry
      */
    function changeExpiryLimit(uint256 _newExpiry) public onlyOwner {//만료기한변경
        require(_newExpiry >= 1 days);
        uint256 _oldExpiry = expiryLimit;
        expiryLimit = _newExpiry;
        emit LogChangeExpiryLimit(_oldExpiry, _newExpiry);//만료기간 변경하도록 이벤트 발생
    }

    /**
     * @dev set the address of the Security Token registry
     * @param _stRegistry contract address of the STR
     * @return bool
     */
    function setTokenRegistry(address _stRegistry) public onlyOwner returns(bool) {
        require(_stRegistry != address(0) && strAddress == address(0));
        strAddress = _stRegistry;
        return true;
    }

    /**
     * @dev Check the validity of the symbol
     * @param _symbol token symbol
     * @param _owner address of the owner
     * @param _tokenName Name of the token
     * @return bool
     */
    function checkValidity(string _symbol, address _owner, string _tokenName) public returns(bool) {
        string memory symbol = upper(_symbol);
        require(msg.sender == strAddress);
        require(registeredSymbols[symbol].status != true);
        require(registeredSymbols[symbol].owner == _owner);
        require(registeredSymbols[symbol].timestamp.add(expiryLimit) >= now);
        registeredSymbols[symbol].tokenName = _tokenName;
        registeredSymbols[symbol].status = true;
        return true;
    }

    /**
     * @dev Returns the owner and timestamp for a given symbol
     * @param _symbol symbol
     */
    function getDetails(string _symbol) public view returns (address, uint256, string, bytes32, bool) {
        string memory symbol = upper(_symbol);
        if (registeredSymbols[symbol].status == true||registeredSymbols[symbol].timestamp.add(expiryLimit) > now) {
            return
            (
                registeredSymbols[symbol].owner,
                registeredSymbols[symbol].timestamp,
                registeredSymbols[symbol].tokenName,
                registeredSymbols[symbol].swarmHash,
                registeredSymbols[symbol].status
            );
        }else
            return (address(0), uint256(0), "", bytes32(0), false);
    }

    /**
     * @dev To re-initialize the token symbol details if symbol validity expires
     * @param _symbol token symbol
     */
    function expiryCheck(string _symbol) internal returns(bool) {
        if (registeredSymbols[_symbol].owner != address(0)) {
            if (now > registeredSymbols[_symbol].timestamp.add(expiryLimit) && registeredSymbols[_symbol].status != true) {
                registeredSymbols[_symbol] = SymbolDetails(address(0), uint256(0), "", bytes32(0), false);
                return true;
            }else
                return false;
        }
        return true;
    }





}