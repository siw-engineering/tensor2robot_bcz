FROM nvidia/cudagl:10.2-devel-ubuntu18.04
# Tools I find useful during development
RUN apt-get update -qq \
 && apt-get install -y -qq \
        build-essential \
        bwm-ng \
        cmake \
        cppcheck \
        gdb \
        git \
        libbluetooth-dev \
        libcwiid-dev \
        libgoogle-glog-dev \
        libspnav-dev \
        libusb-dev \
        lsb-release \
        python3-dbg \
        python3-empy \
        python3-numpy \
        python3-setuptools \
        python3-pip \
        python3-venv \
        ruby2.5 \
        ruby2.5-dev \
        software-properties-common \
        sudo \
        vim \
        wget \
        net-tools \
        iputils-ping \
 && apt-get clean -qq

# Add a user with the same user_id as the user outside the container
# Requires a docker build argument `user_id`
ARG user_id
ENV USERNAME developer
RUN useradd -U --uid ${user_id} -ms /bin/bash $USERNAME \
 && echo "$USERNAME:$USERNAME" | chpasswd \
 && adduser $USERNAME sudo \
 && echo "$USERNAME ALL=NOPASSWD: ALL" >> /etc/sudoers.d/$USERNAME

# Commands below run as the developer user
USER $USERNAME

# Make a couple folders for organizing docker volumes
RUN mkdir ~/workspaces ~/other 
RUN mkdir ~/datasets


# When running a container start in the developer's home folder
WORKDIR /home/$USERNAME

RUN export DEBIAN_FRONTEND=noninteractive \
 && sudo apt-get update -qq \
 && sudo -E apt-get install -y -qq \
    tzdata \
 && sudo ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime \
 && sudo dpkg-reconfigure --frontend noninteractive tzdata \
 && sudo apt-get clean -qq

RUN sudo apt update -qq \
 && sudo apt install -y -qq curl gnupg2 lsb-release
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -

RUN sudo apt-get install -y -qq cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev

RUN sudo apt-get install -y libtbb2 libtbb-dev

RUN sudo apt-get install -y libjpeg-dev libpng-dev libtiff5-dev libdc1394-22-dev libeigen3-dev libtheora-dev libvorbis-dev libxvidcore-dev libx264-dev sphinx-common libtbb-dev yasm libfaac-dev libopencore-amrnb-dev libopencore-amrwb-dev libopenexr-dev libgstreamer-plugins-base1.0-dev libavutil-dev libavfilter-dev libavresample-dev


RUN sudo sh -c 'echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list'

 
RUN sudo apt install -y libpython3-dev

#install cudnn
RUN mkdir ~/deps \
&& cd ~/deps \
&& wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/libcudnn8_8.2.2.26-1+cuda10.2_amd64.deb \
&& wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/libcudnn8-dev_8.2.2.26-1+cuda10.2_amd64.deb

RUN cd ~/deps/ \
&& sudo dpkg -i ~/deps/libcudnn8_8.2.2.26-1+cuda10.2_amd64.deb \
&& sudo dpkg -i ~/deps/libcudnn8-dev_8.2.2.26-1+cuda10.2_amd64.deb

#GPG key error resolution
RUN sudo rm /etc/apt/sources.list.d/cuda.list
RUN sudo apt-key del 7fa2af80
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends wget
WORKDIR /tmp
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-keyring_1.0-1_all.deb
RUN sudo dpkg -i cuda-keyring_1.0-1_all.deb

# python 3.8
RUN sudo add-apt-repository ppa:deadsnakes/ppa
RUN sudo apt-get update

RUN sudo apt-get install -y python3.7

RUN sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 1
RUN python3 -m pip install pip


# update pip
RUN sudo python3 -m pip install --upgrade pip \
&& sudo pip3 install -U --timeout 1000 opencv-python

# install tensor2robot dependencies
RUN pip3 install tensorflow==1.15.5 tensorflow-serving-api==1.15.0 gin-config==0.1.4 pybullet==2.0.0
WORKDIR /home/$USERNAME/
