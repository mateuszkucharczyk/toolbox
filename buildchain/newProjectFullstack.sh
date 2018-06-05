#!/bin/bash

function main() {
	local projectId=${1:?"[ERROR] Specify a project id"};
	local groupId="com.protonmail.mateuszkucharczyk.${projectId}";
	
	mkdir "${projectId}";
	cd "${projectId}";
	git init .
	$(createFileRootPom "${groupId}" "pom.xml");
	
	mkdir "fe";
	$(createFileFrontendPom "${groupId}" "fe/pom.xml");
	
	ng new "${projectId}" -dir fe --skip-tests true --skip-git true --skip-commit true --skip-install true;	
	# https://spring.io/blog/2013/12/19/serving-static-web-content-with-spring-boot
	# Spring Boot will automatically add static web resources located within any of the following directories:
	# - /META-INF/resources/
	# - /resources/
	# - /static/
	# - /public/
	# Change build output directory to one of the above directories. This will make them included in jar and automatically served. 
	sed -i 's/"outDir":\s*".*"/"outDir": "target\/classes\/public"/' "fe/.angular-cli.json"
	
	# Add build command to be used by maven. It must use local ng installed by frontend-maven-plugin. 
	sed -i 's/"scripts": [{]/"scripts": \{\n    "mavenbuild": "node node\/node_modules\/@angular\/cli\/bin\/ng build",/' "fe/package.json"
	
	mkdir "be";
	echo $(createFileBackendPom "${groupId}" "be/pom.xml");
	
	local package="${groupId}";
	local packageDir="$(echo ${package} | sed 's/\./\//g')";

	local mainApplicationDir="be/src/main/java/${packageDir}";
	mkdir -p "${mainApplicationDir}";
	$(createFileApplication "${package}" "${mainApplicationDir}/Application.java");
	
	local testApplicationDir="be/src/test/java/${packageDir}";
	mkdir -p "${testApplicationDir}";
	$(createFileApplicationTest "${package}" "${testApplicationDir}/ApplicationTest.java");

	mkdir -p "be/src/main/resources";
	mkdir -p "be/src/test/resources";
	
	# TODO add .gitignore
	# git add .;
	# git commit -m "initial commit";
}

function createFileApplication() {
local package=${1:?"[ERROR] missing package"};
local file=${2:?"[ERROR] missing file"};
echo "package ${package};" > "${file}"; # substitute package
echo '
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}
}' >> "${file}";
}

function createFileApplicationTest() {
local package=${1:?"[ERROR] missing package"};
local file=${2:?"[ERROR] missing file"};
echo "package ${package};" > "${file}"; # substitute package
echo '
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest
public class ApplicationTest {

	@Test
	public void contextLoads() {
	}

}' >> "${file}";
}

function createFileBackendPom() {
local groupId=${1:?"[ERROR] missing groupId"};
local file=${2:?"[ERROR] missing file"};
echo '<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>' > "${file}";
echo "	<groupId>${groupId}</groupId>" >> "${file}"; # substitute groupId
echo '	<artifactId>be</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<packaging>jar</packaging>

	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>1.5.10.RELEASE</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>

	<properties>
		<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
		<project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
		<java.version>1.8</java.version>
	</properties>

	<dependencies>
		<!-- web dependencies -->
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-validation</artifactId>
		</dependency>
		<dependency>			
			<groupId>${project.groupId}</groupId>
			<artifactId>fe</artifactId>
			<version>0.0.1-SNAPSHOT</version>
		</dependency>
		<!-- persistence dependencies -->
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-data-jpa</artifactId>
		</dependency>
		<dependency>
			<groupId>com.h2database</groupId>
			<artifactId>h2</artifactId>
			<scope>runtime</scope>
		</dependency>
		<!-- anti-boilerplate dependencies -->
		<dependency>
			<groupId>org.projectlombok</groupId>
			<artifactId>lombok</artifactId>
			<optional>true</optional>
		</dependency>
		<!-- test dependencies  -->
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>
	</dependencies>

	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
		</plugins>
	</build>
</project>' >> "${file}";
	
}
function createFileFrontendPom() {
local groupId=${1:?"[ERROR] missing groupId"};
local file=${2:?"[ERROR] missing file"};
echo '<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>' > "${file}";
echo "  <groupId>${groupId}</groupId>" >> "${file}"; # substitute groupId
echo '  <artifactId>fe</artifactId>
  <version>0.0.1-SNAPSHOT</version>
  <packaging>jar</packaging>

  <properties>
	<frontend.plugin.version>1.5</frontend.plugin.version>
	<node.version>v6.11.3</node.version>
	<npm.version>5.4.2</npm.version>
  </properties>
	
  <build>
    <plugins>
        <plugin>
          <groupId>com.github.eirslett</groupId>
          <artifactId>frontend-maven-plugin</artifactId>
          <version>${frontend.plugin.version}</version>
          <configuration>
              <workingDirectory>${project.basedir}</workingDirectory>
          </configuration>
          <executions>
            <execution>
              <id>npm build</id>
              <goals>
                <goal>npm</goal>
              </goals>
              <phase>compile</phase>
              <configuration>
                <arguments>run-script mavenbuild</arguments>
              </configuration>
            </execution>
          </executions>
        </plugin>
    </plugins>
  </build>

  <profiles>
    <profile>
      <id>setup</id>
      <build>
        <plugins>
          <plugin>
            <groupId>com.github.eirslett</groupId>
            <artifactId>frontend-maven-plugin</artifactId>
            <version>${frontend.plugin.version}</version>
            <configuration>
              <workingDirectory>${project.basedir}</workingDirectory>
            </configuration>
            <executions>
              <execution>
                <id>install node and npm</id>
                <goals>
                  <goal>install-node-and-npm</goal>
                </goals>
                <phase>initialize</phase>
                <configuration>
                  <nodeVersion>${node.version}</nodeVersion>
                  <npmVersion>${npm.version}</npmVersion>
                </configuration>
              </execution>
              <execution>
                <id>install angular-cli</id>
                <goals>
                  <goal>npm</goal>
                </goals>
                <phase>initialize</phase>
                <configuration>
                  <arguments>install --no-optional -g @angular/cli</arguments>
                </configuration>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
    </profile>
	<profile>
		<id>npm install</id>
		<activation>
			<property>
				<name>skipNpmInstall</name>
				<value>!true</value>
			</property>
		</activation>		
		<build>
			<plugins>
				<plugin>
				  <groupId>com.github.eirslett</groupId>
				  <artifactId>frontend-maven-plugin</artifactId>
				  <version>1.5</version>
				  <configuration>
					  <workingDirectory>${project.basedir}</workingDirectory>
				  </configuration>
				  <executions>
					<execution>
						<id>npm install</id>
						<goals>
						  <goal>npm</goal>
						</goals>
						<phase>generate-resources</phase>
						<configuration>
						  <arguments>install</arguments>
						</configuration>
					</execution>
				  </executions>
				</plugin>
			</plugins>
		</build>
	</profile>
  </profiles>
</project>' >> "${file}";
}

function createFileRootPom() {
local groupId=${1:?"[ERROR] missing groupId"};
local file=${2:?"[ERROR] missing file"};
echo '<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>' > "${file}";
echo "    <groupId>${groupId}</groupId>" >> "${file}"; # substitute package groupId
echo "    <artifactId>parent</artifactId>" >> "${file}"; 
echo '    <version>0.0.1-SNAPSHOT</version>
    <packaging>pom</packaging>
    <modules>
        <module>fe</module>
        <module>be</module>
    </modules>
</project>' >> "${file}";
}

main "$@";
