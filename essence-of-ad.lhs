%% -*- latex -*-

% Presentation
%\documentclass[aspectratio=1610]{beamer} % Macbook Pro screen 16:10
\documentclass{beamer} % default aspect ratio 4:3
%% \documentclass[handout]{beamer}

% \setbeameroption{show notes} % un-comment to see the notes

\input{macros}

%include polycode.fmt
%include forall.fmt
%include greek.fmt
%include formatting.fmt

\title[]{The simple essence of automatic differentiation}
\date{January 2018}
\institute[]{Target}

\setlength{\itemsep}{2ex}
\setlength{\parskip}{1ex}
\setlength{\blanklineskip}{1.5ex}
\setlength\mathindent{4ex}

\nc\wow\emph

\usepackage{scalerel}

\begin{document}

% \large

\frame{\titlepage}
% \title{Essence of automatic differentiation}
\title{The simple essence of automatic differentiation}
% \title{Simple essence of AD}
% \institute{Target}
\date{Jan 2018}

\framet{What's a derivative?}{

For scalar domain: $$|der f x = lim(epsilon -> 0)(frac(f (x+epsilon) - f x) epsilon)|$$

\ 
\pause
Redefine: unique scalar $s$ such that
 $$ |lim(epsilon -> 0)(frac(f (x+epsilon) - f x) epsilon) - s == 0| $$

\pause
Equivalently,
 $$ |lim(epsilon -> 0)(frac(f (x+epsilon) - (f x + s *^ epsilon)) epsilon) == 0| $$

}

\framet{What's a derivative?}{
For scalar domain:
 $$ |lim(epsilon -> 0)(frac(f (x+epsilon) - (f x + s *^ epsilon)) epsilon) == 0| $$

\pause

Now generalize: unique \wow{linear transformation} $T$ such that

$$|lim(epsilon -> 0)(frac(abs (f (x+epsilon) - (f x + T epsilon)))(abs epsilon)) == 0|$$

\pause\vspace{3ex}

\wow{Derivatives are linear transformations:}

> der :: (a -> b) -> (a -> (a :-* b))

%% Captures all ``partial derivatives'' for all dimensions.

See \emph{Calculus on Manifolds} by Michael Spivak.

}

\framet{Composition}{

Sequential:

\begin{code}
(.) :: (b -> c) -> (a -> b) -> (a -> c)
(g . f) a = g (f a)

NOP
der (g . f) a == der g (f a) . der f a    -- ``chain rule''
\end{code}

\pause

Parallel:

\begin{code}
(&&&) :: (a -> c) -> (a -> d) -> (a -> c :* d)
(f &&& g) a = (f a, g a)

NOP
der (f &&& g) a == der f a &&& der g a
\end{code}

}

\framet{Compositionality}{

Chain rule:

> der (g . f) a == der g (f a) . der f a     -- non-compositional

\ 

To fix, combine regular result with derivative:
\begin{code}
andDer :: (a -> b) -> (a -> (b :* (a :-* b)))
andDer f = f &&& der f     -- specification
\end{code}

Often much work in common to |f| and |der f|.
}

\framet{Linear functions}{

Linear functions are their own perfect linear approximations.

\begin{code}
der id   a  =  id
der fst  a  =  fst
der snd  a  =  snd
            ...
\end{code}

For linear functions |f|,

> andDer f a = (f a, f)

%% > andDer f = f &&& const f

}

%% \nc\scrk[1]{_{\hspace{#1}\scriptscriptstyle{(\leadsto)\!}}}
\nc\scrk[1]{_{\hspace{#1}\scaleto{(\leadsto)\!}{4pt}}}

%format ProductCat = Cartesian
%format CoproductCat = Cocartesian
%format CoproductPCat = Cocartesian

%format Prod (k) a b = a "\times\scrk{-0.4ex}" b
%format Coprod (k) a b = a "+\scrk{-0.4ex}" b
%% %format Exp (k) a b = a "\Rightarrow\scrk{-0.2ex}" b

%%  %format da = "\Delta a"
%%  %format db = "\Delta b"

%format `k` = "\leadsto"
%format k = "(\leadsto)"

%% %format `k` = "\rightsquigarrow"
%% %format k = "(\rightsquigarrow)"



\framet{Abstract algebra for functions}{
\begin{code}
class Category k where
  id   :: a `k` a
  (.)  :: (b `k` c) -> (a `k` b) -> (a `k` c)

class Category k => ProductCat k where
  type Prod k a b
  exl    ::  (Prod k a b) `k` a
  exr    ::  (Prod k a b) `k` b
  (&&&)  ::  (a `k` c)  -> (a `k` d)  -> (a `k` (Prod k c d))

class Category k => CoproductCat k where
  type Coprod k a b
  inl    ::  a `k` (Coprod k a b)
  inr    ::  b `k` (Coprod k a b)
  (|||)  ::  (a `k` c)  -> (b `k` c)  -> ((Coprod k a b) `k` c)
\end{code}

\vspace{-1ex}
Plus laws and classes for arithmetic etc.
}

%format cosC = cos
%format sinC = sin
%format mulC = mul
%format addC = add
%format negateC = negate

\framet{Simple automatic differentiation}{
\mathindent-1ex
\begin{code}
data D a b = D (a -> b :* (a :-* b))
\end{code}
\pause
\vspace{-4ex}
\begin{code}
linearD f = D (f &&& const f)

instance Category D where
  id = linearD id
  D g . D f = D (\ a -> let { (b,f') = f a ; (c,g') = g b } in (c, g' . f'))

instance Cartesian D where
  exl  = linearD exl
  exr  = linearD exr
  D f &&& D g = D (\ a -> let { (b,f') = f a ; (c,g') = g a } in ((b,c), f' &&& g'))

instance NumCat D where
  negateC = linearD negateC
  addC  = linearD addC
  mulC  = D (mulC &&& \ (a,b) -> (\ (da,db) -> b*da + a*db))
\end{code}
}

\framet{Running examples}{
\begin{code}
sqr :: Num a => a -> a
sqr a = a * a

magSqr :: Num a => a :* a -> a
magSqr (a,b) = sqr a + sqr b

cosSinProd :: Floating a => a :* a -> a :* a
cosSinProd (x,y) = (cos z, sin z) where z = x * y
\end{code}

In categorical vocabulary:

\begin{code}
sqr = mulC . (id &&& id)

magSqr = addC . (mulC . (exl &&& exl) &&& mulC . (exr &&& exr))

cosSinProd = (cosC &&& sinC) . mulC
\end{code}
}

\framet{Visualizing computations}{
\begin{code}
magSqr (a,b) = sqr a + sqr b
NOP
magSqr = addC . (mulC . (exl &&& exl) &&& mulC . (exr &&& exr))
\end{code}
\vspace{-5ex}
\begin{center}\wpicture{4in}{magSqr}\end{center}

Auto-generated from Haskell code.
See \href{http://conal.net/papers/compiling-to-categories/}{\emph{Compiling to categories}}.
}

\framet{AD example}{
\vspace{4ex}
\begin{code}
sqr a = a * a

sqr = mulC . (id &&& id)
\end{code}
\begin{textblock}{160}[1,0](357,37)
\begin{tcolorbox}
\wpicture{2in}{sqr}
\end{tcolorbox}
\end{textblock}
\pause

\vspace{0ex}
\begin{center}\wpicture{4.8in}{sqr-adf}\end{center}

%% \figoneW{0.51}{cosSinProd-ad}{|andDeriv cosSinProd|}{\incpic{cosSinProd-ad}}}
}

\framet{AD example}{
\vspace{8ex}
\begin{code}
magSqr (a,b) = sqr a + sqr b

magSqr = addC . (mulC . (exl &&& exl) &&& mulC . (exr &&& exr))
\end{code}
\begin{textblock}{160}[1,0](357,37)
\begin{tcolorbox}
\wpicture{2in}{magSqr}
\end{tcolorbox}
\end{textblock}
\pause

\vspace{-4ex}
\begin{center}\wpicture{4.5in}{magSqr-adf}\end{center}

}

\framet{AD example}{
\vspace{12ex}
\begin{code}
cosSinProd (x,y) = (cos z, sin z) where z = x * y
\end{code}
\begin{textblock}{160}[1,0](357,37)
\begin{tcolorbox}
\wpicture{2in}{cosSinProd}
\end{tcolorbox}
\end{textblock}
\pause

\begin{center}\wpicture{4.5in}{cosSinProd-adf}\end{center}
}

\framet{Generalizing AD}{
\mathindent-1ex
\begin{code}
data D a b = D (a -> b :* (a :-* b))
\end{code}
\pause
\vspace{-6ex}
\begin{code}
linearD f = D (f &&& const f)

instance Category D where
  id = linearD id
  D g . D f = D (\ a -> let { (b,f') = f a ; (c,g') = g b } in (c, g' . f'))

instance Cartesian D where
  exl  = linearD exl
  exr  = linearD exr
  D f &&& D g = D (\ a -> let { (b,f') = f a ; (c,g') = g a } in ((b,c), f' &&& g'))
\end{code}

\vspace{0.5ex}
\pause

Each |D| operation just uses corresponding |(:-*)| operation.

Generalize from |(:-*)| to other cartesian categories.
}

\framet{Generalized AD}{
\mathindent-1ex
\begin{code}
data GD k a b = D (a -> b :* (a `k` b))

linearD f = D (f &&& const f)

instance Category k => Category (GD k) where
  id = linearD id
  D g . D f = D (\ a -> let { (b,f') = f a ; (c,g') = g b } in (c, g' . f'))

instance Cartesian k => Cartesian (GD k) where
  exl  = linearD exl
  exr  = linearD exr
  D f &&& D g = D (\ a -> let { (b,f') = f a ; (c,g') = g a } in ((b,c), f' &&& g'))
\end{code}

\vspace{8ex}
}

%format inlP = inl
%format inrP = inr
%format |||| = |||
%format ++++ = +++

\framet{Numeric operations}{
Specific to (linear) \emph{functions}:

>      mulC  = D (mulC &&& \ (a,b) -> (\ (da,db) -> b*da + a*db))

\pause

Rephrase:

\begin{code}
scale :: Multiplicative a => a -> (a -> a)
scale u = \ v -> u * v

(||||) :: Additive c => (a -> c) -> (b -> c) -> ((a :* b) -> c)
f |||| g = \ (a,b) -> f a ^+^ g b
\end{code}

Now

>      mulC  = D (mulC &&& (scale b |||| scale a))

}

\framet{Linear arrow vocabulary}{
\begin{code}
class Category k where
  id   :: a `k` a
  (.)  :: (b `k` c) -> (a `k` b) -> (a `k` c)

class Category k => ProductCat k where
  exl    :: (a :* b) `k` a
  exr    :: (a :* b) `k` b
  (&&&)  :: (a `k` c) -> (a `k` d) -> (a `k` (c :* d))

class Category k => CoproductCat k where
  inl    :: Additive b  => a `k` (a :* b)
  inr    :: Additive a  => b `k` (a :* b)
  (|||)  :: Additive c  => (a `k` c) -> (b `k` c) -> ((a :* b) `k` c)

class ScalarCat k a where
  scale :: a -> (a `k` a)
\end{code}
}

\framet{Core vocabulary}{
\begin{code}
  scale  :: a -> (a `k` a)                              -- $1\times1$

  (|||)  :: (a `k` c) -> (b `k` c) -> ((a :* b) `k` c)  -- horizontal juxt

  (&&&)  :: (a `k` c) -> (a `k` d) -> (a `k` (c :* d))  -- vertical juxt
\end{code}

\vspace{2ex}
Sufficient to build arbitrary matrices.

\vspace{4ex}
Types guarantee rectangularity.
}

%format Double = R

%format -+> = "\mathbin{\rightarrow^{\!\!+}\!}"
%% %format -+> = "\rightarrow_{\!\!+}"
%% %format -+> = "\overset{+}{\longrightarrow}"
%% %format -+> = "\overset{{}_{+}}{\longrightarrow}"
%% %format -+> = "\rightarrow\hspace{-3ex}^{\scriptscriptstyle +}\hspace{2ex}"
%% %format -+> = "\mathbin{\longrightarrow\hspace{-3ex}{+}\hspace{0.7ex}}"

%format inNew2

\framet{Linear transformations as functions}{
\vspace{-1.2ex}
\begin{code}
newtype a -+> b = AddFun (a -> b)

instance Category (-+>) where
  type Ok (-+>) = Additive
  id   = AddFun id
  (.)  = inNew2 (.)

instance ProductCat (-+>) where
  exl    = AddFun exl
  exr    = AddFun exr
  (&&&)  = inNew2 (&&&)

instance CoproductPCat (-+>) where
  inlP   = AddFun (,zero)
  inrP   = AddFun (zero,)
  (||||) = inNew2 (\ f g (x,y) -> f x ^+^ g y)

instance Num s => ScalarCat (-+>) s where
  scale s = AddFun (s NOP *)
\end{code}
}

\framet{Extracting a data representation}{

\begin{itemize}\itemsep2ex \parskip1ex
\item How to extract a matrix or gradient vector?
\item Sample over a domain \emph{basis} (rows of identity matrix).
\item For $n$-dimensional \emph{domain},
  \begin{itemize}\itemsep2ex
  \item Make $n$ passes.
  \item Each pass works on $n$-D sparse (``one-hot'') input.
  \end{itemize}
\item For gradient-based optimization,
  \begin{itemize}\itemsep2ex
  \item High-dimensional domain.
  \item Very low-dimensional (1-D) domain.
  \end{itemize}
\end{itemize}
}

\framet{A ``matrix'' representation}{\mathindent2ex
\begin{code}
newtype L s a b = L (V s b (V s a s))

class HasV s a where
  type V s a :: * -> * -- Free vector space as representable functor
  toV  :: a -> V s a s
  unV  :: V s a s -> a

instance HasV Double Double where
  type V Double Double = Par1
  toV  = Par1
  unV  = unPar1

instance (HasV s a, HasV s b) => HasV s (a :* b) where
  type V s (a :* b) = V s a :*: V s b
  toV (a , b)    = toV a :*: toV b
  unV (f :*: g)  = (unV f,unV g)
\end{code}
}

\framet{Efficiency of composition}{
\begin{itemize}\itemsep2ex \parskip0.5ex
\item
  Some orders of composition are more efficient than others.
\item
  Fortunately, arrow composition is associative:
  \begin{itemize}\itemsep2ex
  \item Associate optimally.
  \item Equivalent to \emph{matrix chain multiplication} --- $O(n \log n)$.
  \item Choice determined by \emph{types}, i.e., compile-time information.
  \end{itemize}
\pitem
  All-right composition gives ``forward mode AD'' (FAD).\\
  Good for low-dimensional domains.
\item
  All-left composition gives ``reverse mode AD'' (RAD).\\
  Good for low-dimensional codomains.
\item
  RAD is a much better choice for gradient-based optimization.
\end{itemize}
}

%format --> = "\mapsto"
\framet{Left-associating composition (RAD)}{
\begin{itemize}\itemsep2ex \parskip1ex
\pitem CPS-like category:
  \begin{itemize}\itemsep2ex
  \item Represent |a `k` b| by |(b `k` r) -> (a `k` r)|.
  \item Meaning:
    %% |ab --> (\ br -> br . ab)|.
    |f --> (. NOP f)|.
  \item Results in left-composition.
  \item Corresponds to a categorical pullback.
  \item Duality/transposition in linear algebra.
  \end{itemize}
\pitem We've seen this trick before:
  \begin{itemize}\itemsep2ex
  \item Transforming naive |reverse| from quadratic to linear.
  \item Lists generalize to monoids, and monoids to categories.
  \end{itemize}
\end{itemize}
}

\framet{One of my favorite papers}{
  \begin{itemize}\itemsep2ex \parskip1ex
  \item \href{http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.83.8567}{\emph{Continuation-Based Program Transformation Strategies}} \\ Mitch Wand, 1980, JACM.
  \item Introduce a continuation argument, e.g., |[a] -> [a]|.
  \item Notice the continuations that arise, e.g., |(++ as)|.
  \pitem Find a \emph{data} representation, e.g., |as :: [a]|
  \item Identify associative operation that represents composition,\\
  e.g., |(++)| , since |(++ bs) . (++ as) == (++ NOP (as ++ bs))|.
  \end{itemize}
}

\framet{Duality}{
\begin{itemize}\itemsep2.5ex
\item Vector space dual: |U :-* r|, with |U| a vector space over |r|.
\item If |U| has finite dimension, then |U :-* r =~= U|.
\item For |f :: U :-* r|, |f == dot v| for some |v :: U|.
\item Gradients are derivatives of functions with scalar codomain.
\item Represent |a `k` b| by |(b `k` r) -> (a `k` r)| by |b -> a|.
\pitem \emph{Ideal} for extracting gradient vector.
       Just apply to |1|.
\pitem Construct |dot v . der f a| directly, without |dot v| or |der f a|.\\
       Eliminates matrices (often large \& sparse).
%% \item Often don't need vector space; semi-module will do.
%% \item Semimodule suffices in place of vector space.
\end{itemize}
}

\framet{Dual categories}{
\begin{code}
newtype Dual k a b = Dual (b `k` a)

instance Category k => Category (Dual k) where
  id   = Dual id
  (.)  = inNew2 (flip (.))

instance CoproductCat k => ProductCat (Dual k) where
  exl    = Dual inlP
  exr    = Dual inrP
  (&&&)  = inNew2 (||||)

instance ProductCat k => CoproductPCat (Dual k) where
  inlP    = Dual exl
  inrP    = Dual exr
  (||||)  = inNew2 (&&&)

instance ScalarCat k s => ScalarCat (Dual k) s where
  scale s = Dual (scale s)
\end{code}
}

\framet{Reverse-mode AD without tears}{
\begin{code}
type RAD = GD (Dual (-+>))
\end{code}
}

\framet{RAD example (dual function)}{
\vspace{2ex}
\begin{textblock}{160}[1,0](357,37)
\begin{tcolorbox}
\wpicture{2in}{add}
\end{tcolorbox}
\end{textblock}
\vspace{4ex}
\begin{center}\hspace{-5ex}\wpicture{4in}{add-adr}\end{center}
}
\framet{RAD example (gradient)}{
\vspace{2ex}
\begin{textblock}{160}[1,0](357,37)
\begin{tcolorbox}
\wpicture{2in}{add}
\end{tcolorbox}
\end{textblock}
\vspace{4ex}
\begin{center}\hspace{-5ex}\wpicture{4in}{add-gradr}\end{center}
}

\framet{RAD example (dual function)}{
\vspace{2ex}
\begin{textblock}{130}[1,0](357,37)
\begin{tcolorbox}
\wpicture{1.5in}{fst}
\end{tcolorbox}
\end{textblock}
\vspace{6ex}
\begin{center}\hspace{-8ex}\wpicture{3.7in}{fst-adr}\end{center}
}
\framet{RAD example (gradient)}{
\vspace{2ex}
\begin{textblock}{130}[1,0](357,37)
\begin{tcolorbox}
\wpicture{1.5in}{fst}
\end{tcolorbox}
\end{textblock}
\vspace{5ex}
\begin{center}\hspace{-8ex}\wpicture{2.5in}{fst-gradr}\end{center}
}

\framet{RAD example (dual function)}{
\vspace{2ex}
\begin{textblock}{160}[1,0](357,37)
\begin{tcolorbox}
\wpicture{2in}{sqr}
\end{tcolorbox}
\end{textblock}
\vspace{8ex}
\begin{center}\hspace{-2ex}\wpicture{4.5in}{sqr-adr}\end{center}
}
\framet{RAD example (gradient)}{
\vspace{2ex}
\begin{textblock}{160}[1,0](357,37)
\begin{tcolorbox}
\wpicture{2in}{sqr}
\end{tcolorbox}
\end{textblock}
\vspace{7ex}
\begin{center}\hspace{-2ex}\wpicture{4in}{sqr-gradr}\end{center}
}

\framet{RAD example (dual function)}{
\vspace{2ex}
\begin{textblock}{160}[1,0](357,37)
\begin{tcolorbox}
\wpicture{2in}{magSqr}
\end{tcolorbox}
\end{textblock}
\vspace{4ex}
\begin{center}\hspace{-2ex}\wpicture{4.5in}{magSqr-adr}\end{center}
}
\framet{RAD example (gradient)}{
\vspace{2ex}
\begin{textblock}{160}[1,0](357,37)
\begin{tcolorbox}
\wpicture{2in}{magSqr}
\end{tcolorbox}
\end{textblock}
\vspace{8ex}
\begin{center}\hspace{-4ex}\wpicture{4in}{magSqr-gradr}\end{center}
}

\framet{RAD example (dual function)}{
\vspace{2ex}
\begin{textblock}{160}[1,0](357,37)
\begin{tcolorbox}
\wpicture{2in}{cosSinProd}
\end{tcolorbox}
\end{textblock}
\vspace{8ex}
\begin{center}\hspace{-0.5ex}\wpicture{4.8in}{cosSinProd-adr}\end{center}
}
\framet{RAD example (matrix)}{
\vspace{2ex}
\begin{textblock}{160}[1,0](357,37)
\begin{tcolorbox}
\wpicture{2in}{cosSinProd}
\end{tcolorbox}
\end{textblock}
\vspace{8.5ex}
\begin{center}\hspace{-2ex}\wpicture{4.4in}{cosSinProd-adrl}\end{center}
}

%% HERE: use linear

\end{document}
