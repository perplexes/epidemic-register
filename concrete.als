
/*

Concrete executions

From Principles of Eventual Conistency by Sebastian Burckhardt

*/

open util/ordering[Role]

open util/relation

abstract sig Value {}

// Events. We use "E" here because it's shorter, and this is referenced often
abstract sig E {
    , role: one Role
    , eo: set E
    , del: set E,

    // Next element in the role
    , next: lone E
} {
    let E' = role.~@role | // E' is events in the role
        next = {s : E' | s in eo-this and no t : E'-(this+s) | ( (this->t) + (t->s)) in @eo}
}


// Built-in total order is reflexive and we want irreflexive
pred strictTotalOrder[r : univ->univ, A : set univ]  {
    irreflexive[r]
    transitive[r]
    A->A in r + ~r + iden
}

/**
 *  p87, Defintion 7.5
 */ 
fact "Concrete executions" {
    // c1: eo is an eumeration of E, which is effectively a total order
    // (It's also natural, but for finite sets that's equivalent)
    strictTotalOrder[eo, E]


    // c2: every event is associated with a transition
    E in Transition

    // c3: every event is associated with a role.
    // Nothing to assert here, it's part of the sig

    // c4: the events for each role are a trajectory
    all r : Role | isTrajectory[r]

    // c5: 
    injective[del, E]
    all s,r : E | (s->r in del) => {
        (s->r in eo) 
        some rcv[r]
        rcv[r] in snd[s]
    }
}

abstract sig Role {}

abstract sig State {}

abstract sig Message {}

abstract sig Transition extends E {
    , rcv: lone Message
    , snd: set Message
    , rval: lone Value

    , pre : lone State
    , post : State
    , M : set Message
}

//
// See definition 7.2, p85
//
abstract sig init extends Transition {
} {
    no this.@rcv
    no pre
    snd = M
    no rval
}

abstract sig call extends Transition {
} {
    no this.@rcv 
    snd = M
    no rval
}

abstract sig recv extends Transition {
    , m : Message
} {
    rcv = m
    snd = M
    no rval
}

abstract sig step extends Transition {
}{
    no this.@rcv
    snd = M
    no rval
}

abstract sig callret extends Transition {
    , v : lone Value
} {
    no this.@rcv
    snd = M
    rval = v
}

abstract sig recvret extends Transition {
    , m : Message
    , v : Value
} {
    rcv = m
    snd = M
    rval = v
}

abstract sig stepret extends Transition {
    , v : Value
} {
    no this.@rcv
    snd = M
    rval = v
}

fact "All transitions have pre states except init" {
    all t : Transition | (no t.pre) => t in init
}

/**
 * Trajectories are defined on p86
 */
pred isTrajectory[r : Role] {

    // t1: eo is an enumeration (total order) of E'
    strictTotalOrder[eo, role.r]

    // t2: every event is associated with a transition
    role.r in Transition

    // t3: The first (and only the first) transition is an initialization transition, 
    // and the pre-state of each transition matches the post-state of the previous transition
    all e : role.r | {
        no pre[e]
        no next.e
    } or pre[e] = post[next.e]


    // t4: A call transition may not follow another call transition unless there is a return transition in between them
    // Not modeling this for now because epidemic register calls all return immediately

    // 7.4: Well-formed trajectories
    // A trajectory (E,eo,tr) is well-formed if each event is preceded by no more returns than calls
    // Not modeling this for now because epidemic register calls all return immediately
}


// 8.3 p109
pred dontforge[M : set Message] {
    all e : E | ((e in recv) && (rcv[e] in M)) => some del.e
}

run { } for 6 but 2 Role