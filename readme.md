## The simple essence of automatic differentiation

See also [the paper's web page](http://conal.net/papers/essence-of-ad/).

This paper is based on an [invited talk for PEPM 2018](https://github.com/conal/talk-2018-essence-of-ad/blob/master/readme.md) (with slides and video) by the same name.
An extended version with full proofs is [on arXiv](https://arxiv.org/abs/1804.00746).
A shorter version will appear at ICFP 2018.

### Abstract

Automatic differentiation (AD) in reverse mode (RAD) is a central component of deep learning and other uses of large-scale optimization. Commonly used RAD algorithms such as backpropagation, however, are complex and stateful, hindering deep understanding, improvement, and parallel execution. This paper develops a simple, generalized AD algorithm calculated from a simple, natural specification. The general algorithm is then specialized by varying the representation of derivatives. In particular, applying well-known constructions to a naive representation yields two RAD algorithms that are far simpler than previously known. In contrast to commonly used RAD implementations, the algorithms defined here involve no graphs, tapes, variables, partial derivatives, or mutation. They are inherently parallel-friendly, correct by construction, and usable directly from an existing programming language with no need for new data types or programming style, thanks to use of an AD-agnostic compiler plugin.
