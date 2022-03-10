FROM jupyter/minimal-notebook:latest

RUN conda install --quiet --yes \
    'matplotlib-base' \
    'plotly' \
    'ipywidgets' \
    'scipy' \
    'ruptures' \
    'resampy' \
    'pandas' && \
    conda clean --all -f -y 
