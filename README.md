# Cognitive Models with Julia

[![](https://img.shields.io/badge/status-looking_for_collaborators-orange)](https://github.com/DominiqueMakowski/CognitiveModels/issues)

The project is to write an open-access book on **cognitive models**, i.e., statistical models that best fit **psychological data** (e.g., reaction times, scales from surveys, ...). 
This framework aims at moving away from a mere description of the data, to make inferences about the underlying cognitive processes that led to its generation.

## Why Julia?

[**Julia**](https://julialang.org/) - the new cool kid on the scientific block - is a modern programming language with many benefits when compared with R or Python.
Importantly, it is currently the only language in which we can fit all the cognitive models under a Bayesian framework using a unified interface like [**Turing**](https://turing.ml/) and [**SSM**](https://github.com/itsdfish/SequentialSamplingModels.jl).

## Why Bayesian?

Unfortunately, cognitive models often involve distributions for which Frequentist estimations are not yet implemented, and usually contain a lot of parameters (due to the presence of **random effects**), which makes traditional algorithms fail to converge.
Simply put, the Bayesian approach is the only one currently robust enough to fit these somewhat complex models.

## The Plan

As this is a fast-evolving field (both from the theoretical - with new models being proposed - and the technical side - with improvements to the packages and the algorithms), the book needs to be future-resilient and updatable to keep up with the latest best practices. 

- [ ] Decide on the framework to build the book in a reproducible and collaborative manner (Quarto?)
- [ ] Set up the infrastructure to automatically build it using GitHub actions and host it on GitHub pages
- [ ] Write the content of the book
- [ ] Referencing
  - Add Zenodo DOI and reference (but how to deal with evolving author? Through versioning?)
  - Publish a paper to present the book project ([JOSE](https://jose.theoj.org/))?


## Looking for Coauthors

This project can only be achieved by a team, and I suspect no single person has currently all the skills and knowledge to cover all the content. We need many people who have strengths in various aspects, such as Julia/Turing, theory, writing, making plots etc.
Most importantly, this project can serve as a way for us to learn more about this approach to psychological science. 

**If you are *interested* in the project, you can let us know by [opening an issue](https://github.com/DominiqueMakowski/CognitiveModels/issues) or getting in touch.**

## Content

See current WIP [**table of content**](https://dominiquemakowski.github.io/CognitiveModels/).
