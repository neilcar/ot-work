FROM reg.mini.dev/python:3.13-dev AS builder 
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/myapp/venv/bin:$PATH"
EXPOSE 8000
WORKDIR /myapp 
RUN python -m venv /myapp/venv
RUN pip3 install uv && uv init && uv add flask pip opentelemetry-distro[otlp] \
  opentelemetry-propagator-aws-xray opentelemetry-exporter-otlp \
  opentelemetry-sdk-extension-aws && uv run opentelemetry-bootstrap -a \
  requirements | uv pip install --requirement - && uv cache clean \
  && pip cache purge 
COPY src/ /myapp/ 

FROM reg.mini.dev/python:3.13
ENV PYTHONUNBUFFERED=1
ENV PATH="/myapp/venv/bin:$PATH"
COPY --chown=1000:1000 --from=builder /myapp /myapp
WORKDIR /myapp
ENTRYPOINT ["uv"] 
CMD ["run", "opentelemetry-instrument", "--traces_exporter", "console", "--metrics_exporter", "console",  "--logs_exporter", "console", "--service_name", "flask-app", "flask", "run", "-p", "8080", "--host=0.0.0.0"]
