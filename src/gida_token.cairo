
#[starknet::interface] // interface of GidaToken
pub trait IGidaToken<TContractState> {
    fn mint(ref self: TContractState, amount: u256);
}

#[starknet::contract]
pub mod GidaToken {
    use super::IGidaToken; // import the interface
    use openzeppelin::access::ownable::OwnableComponent; // import ownable component
    use openzeppelin::token::erc20::{ERC20HooksEmptyImpl, ERC20Component}; // import erc20 component
    use starknet::{ContractAddress, get_caller_address}; // import module for contract address
    use core::num::traits::Zero; // import module for working with is_Zero()
 
    component!(
        path: ERC20Component, storage: erc20, event: ERC20Event
    ); // erc20 component path macro
    component!(
        path: OwnableComponent, storage: ownable, event: OwnableEvent
    ); // ownable component path macro

    // mixin for internal implementation for ERC20
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    // mixin for internal implementation for Ownable
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // custom errors
    pub mod Errors {
        pub const NOT_OWNER: felt252 = 'Caller is not the owner';
        pub const ZERO_ADDRESS_CALLER: felt252 = 'Caller is the zero address';
    }

    // component interaction with contract storage
    #[storage]
    struct Storage {
        owner: ContractAddress,
        #[substorage(v0)]
        erc20: ERC20Component::Storage, // ERC20 storage
        #[substorage(v0)]
        ownable: OwnableComponent::Storage, // Ownable storage
    }

    // component interaction with contract event
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event, // ERC20 events
        #[flat]
        OwnableEvent: OwnableComponent::Event, // Ownable events
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // the token is been initialized: token name: GIDA_TOKEN, token symbol: GIDA
        self.erc20.initializer("GidaToken", "GIDA");
        // the owner is been initialized as owner
        self.ownable.initializer(owner); // initializer function is the component internal function
    }

    #[abi(embed_v0)]
    // implement the GidaToken interface
    impl GidaTokenImpl of IGidaToken<ContractState> {
        fn mint(ref self: ContractState, amount: u256){
            // get the caller address
            let caller: ContractAddress = get_caller_address(); 
            // get the owner address
            let owner: ContractAddress = self.owner.read();
            // check caller is NOT zero address
            assert(!caller.is_zero(), Errors::ZERO_ADDRESS_CALLER);
            // confirm caller is owner
            assert(caller == owner, Errors::NOT_OWNER);
            // mint some token amount to the owner.
            // the openzeppelin mint function is implemented
            self.erc20.mint(owner, amount);
        }
    }
}
