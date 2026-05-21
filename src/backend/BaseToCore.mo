// BaseToCore.mo — Migration helper for mo:base → mo:core
// PARALLAX Sovereign Organism
//
// This module provides migration functions for any mo:base data structures
// that may be present in stable state from older canister versions.
// The current actor state uses mo:core exclusively, so the migration functions
// here serve as the compatibility shim for any legacy state found on upgrade.
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Map "mo:core/Map";
import Set "mo:core/Set";
import List "mo:core/List";
import Order "mo:core/Order";
import Principal "mo:core/Principal";
import OrderedMap "mo:base/OrderedMap";
import OrderedSet "mo:base/OrderedSet";
import ListBase "mo:base/List";

module {

  // migrateOrderedMap — convert mo:base OrderedMap to mo:core Map
  public func migrateOrderedMap<K, V>(old : OrderedMap.Map<K, V>, compare : (implicit : (K, K) -> Order.Order)) : Map.Map<K, V> {
    let ops = OrderedMap.Make(compare);
    let new = Map.empty<K, V>();
    for ((k, v) in ops.entries(old)) {
      new.add(k, v);
    };
    new;
  };

  // migrateOrderedSet — convert mo:base OrderedSet to mo:core Set
  public func migrateOrderedSet<T>(old : OrderedSet.Set<T>, compare : (implicit : (T, T) -> Order.Order)) : Set.Set<T> {
    let ops = OrderedSet.Make(compare);
    let new = Set.empty<T>();
    for (k in ops.vals(old)) {
      new.add(k);
    };
    new;
  };

  // migrateList — convert mo:base List to mo:core List
  public func migrateList<T>(old : ListBase.List<T>) : List.List<T> {
    let list = List.empty<T>();
    for (item in ListBase.toIter(old)) {
      list.add(item);
    };
    list;
  };

  // Access control state migration — standard authorization component shape
  type UserRole = {
    #admin;
    #user;
    #guest;
  };

  public type OldAccessControlState = {
    var adminAssigned : Bool;
    var userRoles : OrderedMap.Map<Principal, UserRole>;
  };

  public type NewAccessControlState = {
    var adminAssigned : Bool;
    userRoles : Map.Map<Principal, UserRole>;
  };

  public func migrateAccessControlState(old : OldAccessControlState) : NewAccessControlState {
    {
      var adminAssigned = old.adminAssigned;
      userRoles = migrateOrderedMap<Principal, UserRole>(old.userRoles);
    };
  };

};
