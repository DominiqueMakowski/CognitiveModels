# Cognitive Models with Julia

![](https://img.shields.io/badge/status-looking_for_collaborators-orange)

The project is to write an open-access book on **cognitive models**, i.e., statistical models that best fit **psychological data** (e.g., reaction times, scales from surveys, ...).

## Why Julia?

[**Julia**](https://julialang.org/) - the new cool kid on the scientific block - is a modern programming language with many benefits when compared with R or Python.
Importantly, it is currently the only language in which we can fit all the cognitive models under a Bayesian framework using a unified interface like [**Turing**](https://turing.ml/).

## Why Bayesian?

Unfortunately, cognitive models often involve distributions for which Frequentist estimations are not yet implemented, and usually contain a lot of parameters (due to the presence of **random effects**), which makes traditional algorithms fail to converge.
Simply put, the Bayesian approach is the only one currently robust enough to fit these somewhat complex models.

## The Plan

As this is a fast-evolving field (both from the theoretical - with new models being proposed - and the technical side - with improvements to the packages and the algorithms), the book needs to be future-resilient and updatable to keep up with the latest best practices. 

- [ ] Decide on the framework to build the book in a reproducible manner (Quarto?)
- [ ] Set up the infrastructure to automatically build it using GitHub actions and host it on GitHub pages
- [ ] Write the content


## Looking for Coauthors

This project can only be achieved by a team, and I suspect no single person has currently all the skills and knowledge to cover all the content. We need many people who have strengths in various aspects, such as Julia/Turing, theory, writing, making plots etc.
Most importantly, this project can serve as a way for us to learn more about this approach to psychological science. 

**So if you are *interested* in cognitive models, give us a shout-out!**

## Content

Remains to be decided. Some ideas:

- **Chapter 1**: Pieces of Puzzle

1. Very quick intro to Julia and Turing
2. Linear Regression: understand what the parameters mean (intercept, slopes, sigma)
3. Boostrapping: Introduce concepts related to pseudo-posterior distribution description.
4. Hierarchical Models: Simpson's paradox, random effects, how to leverage them to model interindividual differences
5. Bayesian estimation: introduce Bayesian estimation and priors over parameters

- **Chapter 2**: Predictors

1. Bayesian mixed linear regression: put everything together
2. Categorical predictors (+ monotonic effects)
3. Interactions
4. Non-linear relationships (polynomial, GAMs)

- **Chapter 3**: Choice and Scales

1. Logistic models for binary data
2. Beta models 
3. OrdBeta models for slider scales

- **Chapter 4**: Reaction Times

1. ExGaussian and Wald
2. DDM
3. LBA
4. ...

