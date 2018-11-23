# Pull base image.
FROM ubuntu:18.04 AS build

ENV DEBIAN_FRONTEND=noninteractive
# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update > /dev/null && \
  apt-get -y -qq upgrade > /dev/null && \
  apt-get install -y -qq build-essential > /dev/null && \
  apt-get install -y -qq software-properties-common > /dev/null && \
  apt-get install -y -qq byobu curl git htop man unzip vim wget > /dev/null && \
  rm -rf /var/lib/apt/lists/*

# Install dotnet core
RUN  \
apt-key adv --keyserver packages.microsoft.com --recv-keys EB3E94ADBE1229CF > /dev/null && \
apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893 > /dev/null && \
sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-bionic-prod bionic main" > /etc/apt/sources.list.d/dotnetdev.list' && \
apt-get update -qq > /dev/null && \
apt-get install dotnet-sdk-2.1 -y -qq > /dev/null && \
apt-get install postgresql-10 postgresql-client-10 -y -qq > /dev/null


# Run the rest of the commands as the ``postgres`` user created by the ``postgres-11`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/10/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/10/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/10/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 15432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Add files.
# ADD ~/.bashrc /root/.bashrc
# ADD ~/.gitconfig /root/.gitconfig
# ADD ~/.scripts /root/.scripts
USER root

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]

FROM build
WORKDIR /app
  
# Copy csproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

ENV ASPNETCORE_URLS=http://+:5000
EXPOSE 5000

# Set the default command to run when starting the container
ENTRYPOINT ["/bin/bash", "start.sh"]
