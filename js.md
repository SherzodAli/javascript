# JS 

## Quick overview

### Types

[Sandbox](https://runjs.app/play)

- **Types** - Number, String, Boolean, Null, Undefined, Array, Object
- Array - collection of values (not a primitive value), having positions indexed from 0
- Object - collection of values, having named positions

- typeof `null` - object (bug of 20-25yo ago, but we can't fix such bugs, will break others)
- typeof `array` - object (not bug, just less specific answer. Array is subtype of object type)

### Operations

- `3 + 1` (`+` - **operator**, 3 and 4 - **operands** - value which will be operated by operator)
- `+` operator is overloaded (has more than 1 behaviour depending on a value, numbers - math, numeric addition; string - concatenation)
- `binary operator` - operator who has only 2 operands (left and right) - `binary` - 2
- `!` - **unary** operator (1, single-operand is envolved in operation, `!` - negation, flip of boolean value)
- `||` - **logical** operator 'or'

### Variable

- `Variable` - named representation of place in memory /RAM/
- `console.log(1)` - `console` is also variable (built-in, js environment is given by browser/nodejs)
- `()` - parentheses are also technically operators (overloaded, after function means 'execute' - function call; or grouping)
- `;` - also sort of operator (not doing anything, denotes finish of statement)

### Expression vs Statements

```js
var age = 39;
age = 1 + (age * 2);
```

- **expression** - like a phrase (`a = 39`, or `age * 2`, even `2` is expression - literal expression)
- **statement** - full sentence (line)

### Decisions /if else/

```js
if (age > 18) {
    goVote();
}

```

- if statement; if/test clause - condition
- curly braces /{}/ grouped together set of statements (like paragraph in a novel)
- **Loops** - way to repeat smth over and over again
- **Function** - collection of things we want to do (procedure; function - compute values and give it back; procedure - do some stuff)
- **Function parameter** - input to a function
- **Interpolated string** - string along with interpolated expressions (result formatted as string)

# Three Pillars in JS

1. Types / Coercion
  - Primitive types
  - Converting types
  - Checking equality
2. Scope / Closures
3. this / Prototypes

## Primitive Types

> In JavaScript, everything is an object
False

- In JS, variables don't have type, values do
- **Primitive** (value, data type) - data that is not an object and has no *methods* or *properties*
- 7: string, number, bigint, boolean, symbol, undefined, null

- typeof null = object; function = function; array = object
- NaN (~~not a number~~) - value representing Not-A-Number

### Fundamental Objects

- There are built-in fundamental objects came historically from Java (copied)
    therefore they have capital letters (`Object`, `Array`, `Function`, `Date`, `RegExp`, `Error`)
- Need to use `new` keyword to instanciate new instance of those
- Other fundamental objects, but don't use `new` keyword with them
    e.g. `String()`, `Number()`, `Boolean()`, we call as function, because it changes value to that type
    they can be used with `new` but it will create new instance

## Converting Types

- The way to convert one type to another: **coercion** (in dynamically-typed language like js)
- `"My age is" + 23` - implicit coercion number to string
- `+` does string concatenation if any operand is string. If all of them numbers - does numeric addition

- Truthy/Falsy - value which becomes True/False if we convert it to boolean
- Falsy: "", 0, -0, null, NaN, false, undefined
- A quality JS program embraces coercions, making sure the types involved in every operation are clear
  - JS does not do these conversions buggy, but rather we aren't clear of what the types are (and we can miss corner cases)
  - if doing math, make it clear that everything already is a number
  - and if it's not already number, make sure that it's obvious that you're turning it into a number

### Coercion Best Practices

> If a feature sometimes **useful** and sometimes **dangerous** and
> **there is a better option** then always use a better option
*(c) "The Good Parts", Crockford*

- His quote is used to say not to  use these coercion mechanisms in JS
- What is *useful*, *dangerous* and *better option*
- **Useful** - when the reader is focused on what's important
- **Dangerous** - when the reader can't tell what will happen
- **Better** - when the reader understands the code

## Checking Equality

- ~~`==` - checks value loose, `===` - checks values string~~
- `==` - allows coercion (types different), `===` - disallows coercion (types same)
- `==` is **not** about comparisons with unknown types,
    it's about comparisons with known type(s), *optionally* where conversions are helpul
- Make your types obvious

```js
var workshop1 = {topic: null};
var workshop2 = {};

if (
    (workshop1.topic === null || workshop1.topic === undefined) &&
    (workshop2.topic === null || workshop2.topic === undefined)
) {
    // ...
}

if (workshop1.topic == null && workshop2.topic == null) {
    // Both does the same thing, but BETTER code
    // More readable. You focus on what's important, not on unimportant details
}

```

## Scope

- **Scope** - where JS engine looks for things (practical definition)
- In non-strict mode, when defining unexisting variable without `var/let/const` keywords, it creates it in global scope
- Undefined variable is NOT undeclared. It's declared, but doesn't have a value

- Functions themselves are values - **first-class value/citizen**
    so they can be assigned to variables, passed as arguments, returned from functions

```js
var clickHandler = function(){} // anonymous function expression
var keyHandler = function keyHandler(){} // named function expression
```

- IIFE - Immediately invoked function expression (used to protect variables from changing from outer scope)

```js
var teacher = "Kyle";

(function anotherTeacher() {
    var teacher = "Suzy"
    console.log(teacher); // Suzy
})();

console.log(teacher); // Kyle
```

- Block scoping (more common way to organize set of variables)

```js
var teacher = "Kyle";
{
    let teacher = "Suzy"
}
```

## Closure

- **Closure** is when a function "remembers" the variables outside of it,
    even if you pass that function elsewhere

```js
function ask(question) {
    // INFO: whatASec is a function has closure over a question variable
    // when ask function is finished, question doesn't get garbage collected
    // because waitASec references (has a pointer) to that place in memory (that's closure)
    setTimeout(function waitASec() {
        console.log(question);
    }, 100)
}

ask("what is closure?");
// what is closure ?
```

## This

- A function's **this** references the execution context for that call,
    detetmined entirely by how the function was called
- A **this**-aware function can thus have a different context each time it's called,
    which makes it more flexible & reusable

```js
var workshop = {
    teacher: "Kyle",
    ask(question): {
        console.log(this.teacher, question);
    },
};

// To determine at what `this` is gonna point
// we don't need to look at object definition, but rather at function call below
// Implicit binding - `workshop` is being binded as context to ask function
workshop.ask("What's implicit binding?");

function ask(question) {
    console.log(this.teacher, question);
}

function otherClass() {
    var myContext = {
        teacher: "Suzy"
    };
    // Explicit binding
    ask.call(myContext, question);
}

otherClass();
```

## Prototypes

- **Prototype** is an object where any instances will be linked to

```js
// like a constructor
function Workshop(teacher) {
    this.teacher = teacher;
}

Workshop.prototype.ask = function(question) {
    // deepJS.teacher
    console.log(this.teacher, question);
}

// object is created by 'new' keyword and is linked to Workshop.prototype
// and because Workshop.prototype has `ask` method, we can call it
// `deepJS` object does NOT have `ask` method
var deepJS = new Workshop("Kyle");
var reactJS = new Workshop("Suzy");

// implicit binding `deepJS` object as context
deepJS.ask("Is 'prototype' a class?");

reactJS.ask("Isn't 'prototype' ugly?");
```

### Class

- `Class` keyword is layered on top of the `prototype` system (ES6)


```js
// JS does the same thing as above
// (creates function and ask method in it's prototype)
class Workshop(teacher) {
    // creates object linked to a prototype object
    constuctor(teacher) {
        this.teacher = teacher;
    }
    ask(question) {
        console.log(this.teacher, question);
    }
}

var deepJS = new Workshop("Kyle");
var reactJS = new Workshop("Suzy");

deepJS.ask("Is 'prototype' a class?");
reactJS.ask("Isn't 'prototype' ugly?");
```
