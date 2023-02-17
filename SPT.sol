// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
 

 /**
 * @dev Safe MatH library.
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction underflow");
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
} 
 /**
 * @dev OwnAble.
 */
contract Ownable {
  address public owner;
  
 /**
 * @dev The Ownable conStructor sets the original `owner` of the contract to the sender account.
 */
   constructor()  {
       owner = msg.sender;
  }

 /**
 * @dev Event in case of the ownerShip being transferred.
 */
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 /**
 * @dev Throws if called by any account other than the owner.
 */
   modifier onlyOwner() {
       require(msg.sender == owner,"Ownership Assertion: Caller of the function is not the owner.");
    _;
  }

 /**
 * @dev Allows the current owner to transfer control of the contract to a newOwner.
 * @param newOwner The address to transfer ownership to.
 */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
  }
}
 

 /**
 * @dev ERC Token Standard #20 Interface.
 */ 
abstract contract ERC20Interface {
    function totalSupply() external virtual returns (uint);
    function balanceOf(address tokenOwner) external virtual  returns (uint balance);
    function allowance(address tokenOwner, address spender) external virtual returns (uint remaining);
    function transfer(address to, uint tokens) public virtual;
    function approve(address spender, uint tokens) public virtual;
    function transferFrom(address from, address to, uint tokens) public virtual;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 /**
 * @dev Contract function to receive approval and execute function in one call.
 */ 
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}
 
 /**
 * @dev Actual token contract.
 */ 
contract SPTToken is ERC20Interface, Ownable {
    using SafeMath for uint256;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping (address => bool) public frozen;

 /**
 * @dev Events for freezing and unfreezing accounts.
 */ 
    event Freeze(address indexed account);
    event Unfreeze(address indexed account);
 
    constructor()  {
        symbol = "SPT";
        name = "Space T";
        decimals = 8;
        _totalSupply = 1000000000 * 10**8;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

       modifier checkBalance(uint tokens) {
       require(balances[msg.sender] >= tokens,"Low balance.");
    _;
  }

    function _decimals() external view returns (uint8) {
        return decimals;
    }

    function totalSupply() external  view override  returns  (uint) {
        return _totalSupply  - balances[address(0)];
    }
  

    function balanceOf(address tokenOwner) external view override returns (uint balance) {
        return balances[tokenOwner];
    }

 /**
 * @dev Transfer function for transferring tokens.
 */ 
    function transfer(address to, uint tokens) public override  {
        require(!frozen[msg.sender], "Frozen address.");
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens); 
    }

 /**
 * @dev Approve function for allowing an address to spend your tokens.
 * @param tokens are the amount to allow, if set to 0 it revokes the allowance of the spender.
 */ 
    function approve(address spender, uint tokens) checkBalance(tokens) public override{
        require(!frozen[msg.sender], "Frozen address.");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);   
    }

 /**
 * @dev Increase allowance for a spender.
 */
    function increaseAllowance(address spender, uint256 tokens)  public {
        require(!frozen[msg.sender] && allowed[msg.sender][spender].add(tokens) <= balances[msg.sender] , "Increase allowance failed.");
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(tokens) ;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    }

 /**
 * @dev Decrease allowance for a spender.
 */
    function decreaseAllowance(address spender, uint256 tokens) public{
        require(allowed[msg.sender][spender] >= tokens,"Decrease Allowance failed.");
        allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(tokens);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    }

 /**
* @dev When called, update allowance in case the owner's balance has decreased 
* to an amount less than the spender's allowance, in that case 
* match the allowance with the balance.
*/
    function updateAllowance(address owner, address spender) public{
        require(allowed[owner][spender] > balances[owner], "Values already correct.");
        allowed[msg.sender][spender] = balances[owner];
    }

 /**
 * @dev Transfer tokens from an address other than yours, if allowed.
 */ 
    function transferFrom(address from, address to, uint tokens) public override {
        require(!frozen[from] && allowed[from][msg.sender] >= tokens, "Transfer failed.");
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
    }

 /**
 * @dev Check remaining allowance.
 */  
    function allowance(address tokenOwner, address spender) external view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

 /**
 * @dev Approve and call.
 */  
    function approveAndCall(address spender, uint tokens, bytes memory data) public {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
       
    }

 /**
 * @dev Freeze an address.
 */ 
    function freeze(address account) onlyOwner public {
        frozen[account] = true;
        emit Freeze(account);
    }

 /**
 * @dev Unfreeze an address.
 */ 
    function unfreeze(address account) onlyOwner public {
        frozen[account] = false;
        emit Unfreeze(account);
    }
  
 /**
 * @dev Function that mints tokens into an account.
 */ 
    function mint(address account, uint256 tokens) public onlyOwner  {
        require(account != address(0), "Mint to the zero address");
        _totalSupply = _totalSupply.add(tokens);
        balances[account] = balances[account].add(tokens);
        emit Transfer(address(0), account, tokens);
    }
  
 /**
 * @dev Burn your own tokens.
 */ 
    function burn(uint256 tokens) public {
        balances[msg.sender] = balances[msg.sender].sub(tokens) ;
        _totalSupply = _totalSupply.sub(tokens) ;
    }

 /**
 * @dev Revert transaction in case of tokens sent directly to contract.
 */  
    fallback () external payable {
       revert();
    }   
    receive () external payable {
       revert();
    } 
}
