FROM jupyter/minimal-notebook:lab-3.2.9

RUN conda install --quiet --yes \
    'matplotlib-base' \
    'plotly' \
    'ipywidgets' \
    'scipy' \
    'ruptures' \
    'resampy' \
    'pandas' && \
    conda clean --all -f -y 